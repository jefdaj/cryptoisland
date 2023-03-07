{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import Text.Pandoc.Options
-- import Text.DocTemplates hiding (Context)

-- import Hakyll.Web.Pandoc
-- import Hakyll.Web.Template
import qualified Data.ByteString.Lazy.Char8 as C

import           Data.Functor.Identity          ( runIdentity )
import qualified Data.Text as T
import qualified Text.Pandoc.Templates as PT

import Control.Monad                  (forM)
import Data.Aeson                     (ToJSON, encode)
import Data.ByteString.Lazy.Internal  (unpackChars)
import Data.List                      (intersect, isInfixOf, isPrefixOf, nub)
import Data.Maybe                     (fromMaybe, fromJust)
import Data.Monoid                    ((<>))
import Data.String.Utils              (replace)
import GHC.Generics                   (Generic)
import Hakyll.Web.Html.RelativizeUrls (relativizeUrlsWith)
import Hakyll.Web.Tags                (tagsDependency)
import Hakyll.Web.Sass                (sassCompiler)
import Text.Jasmine                   (minify)
import System.FilePath                (takeDirectory, takeBaseName, takeFileName, takeExtension, splitFileName)

import Hakyll.Images (loadImage, compressJpgCompiler)

main :: IO ()
main = hakyllWith myHakyllConfig $ do
  -- unique top-level files
  -- note that this excludes root/*.{png,jpg}
  match rootFiles $ route (toRoot Nothing) >> compile copyFileCompiler

  -- static files
  match (("*/*.svg" .&&. complement "*/island*.svg" .&&. complement "aside/boat.svg") .||. "*/*.png" .||. postPng .||. postSvg .||. postTar .||. postSubdirs .||. "about/jefdaj.asc") $ route idRoute >> compile copyFileCompiler
  match ("*/*.jpg" .||. postJpg) $ route idRoute >> compile (loadImage >>= compressJpgCompiler 50)
  match("variables.scss") $ route idRoute >> compile copyFileCompiler
  match ("*.scss" .||. "*/*.scss") $ route (toRoot $ Just "css") >> compile (fmap compressCss <$> sassCompiler)

  -- html templates used below
  -- note that we treat svg as html here because it includes clickable links
  match ("page.html" .||. "posts.html" .||. "*/*.html" .||. "*/island*.svg" .||. "aside/boat.svg") $ compile templateCompiler

  -- most of the rest is crudely updated whenever a tag changes
  tags <- buildTags postMd $ fromCapture "tags/*.html"
  let whenAnyTagChanges = rulesExtraDependencies [tagsDependency tags]

  -- posts (pandoc markdown)
  -- TODO would this ever need updating to deal with a tag change?
  match postMd $ do
    route $ setExtension "html"
    -- route $ customRoute $ \md -> takeDirectory (toFilePath md) ++ ".html"

    -- this part is from:
    -- https://argumatronic.com/posts/2018-01-16-pandoc-toc.html
    -- TODO separate compiler fn
    compile $ do
      ident    <- getUnderlying
      toc      <- getMetadataField ident "toc"
      reminder <- getMetadataField ident "reminder"
      let readerSettings = defaultHakyllReaderOptions
          writerSettings = case toc of
            Just "false" -> withNoToc reminder
            _ -> withToc reminder -- default to adding it unless explicitly false
      pandocCompilerWith readerSettings writerSettings
        >>= saveSnapshot "content" -- for the atom feed
        >>= loadAndApplyTemplate "posts/post.html" (postCtx tags)
        >>= loadAndApplyTemplate "page.html" (postCtx tags)
        >>= relativizeAllUrls

  -- the recent posts page is special because we also use it to create index.html,
  -- and because it's the only one that needs a list of recent posts.
  -- TODO how to flag index.html as different for css?
  create ["recent.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll postMd
      let ctx = recentCtx posts tags
      makeItem ""
        >>= loadAndApplyTemplate "recent/index.html" ctx
        >>= loadAndApplyTemplate "page.html" ctx
        >>= relativizeAllUrls

  -- this mostly is the same as recent.html above
  -- TODO get the padding/margin to match exactly
  create ["index.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll postMd
      let ctx = constField "title" "Home" <> recentCtx posts tags <> constField "extracss" "./index.css"
      makeItem ""
        >>= loadAndApplyTemplate "recent/index.html" ctx
        >>= loadAndApplyTemplate "page.html" ctx
        >>= relativizeAllUrls

  match ("*/index.md" .&&. complement "recent/index.md") $ do
    route (toRoot $ Just "html")
    compile $ pandocCompiler
      >>= loadAndApplyTemplate "page.html" (indexCtx tags)
      >>= relativizeAllUrls

  tagsRules tags $ \tag pattern -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let ctx = tagsCtx posts tags tag
        makeItem ""
          >>= loadAndApplyTemplate "tags/tag.html" ctx
          >>= loadAndApplyTemplate "page.html" ctx
          >>= relativizeAllUrls

  -- TODO should this stay separate, or should you just use recentCtx for everything?
--   match "recent/index.md" $ do
--     route $ toRoot $ Just "html"
--     compile $ do
--       posts <- recentFirst =<< loadAll postMd
--       let ctx = recentCtx posts tags
--       getResourceBody
--         >>= applyAsTemplate ctx
--         >>= loadAndApplyTemplate "page.html" ctx
--         >>= relativizeAllUrls

--   match "index/index.md" $ do
--     route $ customRoute $ const "index.html"
--     compile $ do
--       posts <- recentFirst =<< loadAll postMd
--       let ctx = recentCtx posts tags
--       getResourceBody
--         >>= applyAsTemplate ctx
--         -- TODO factor out the centering stuff so it can be applied here
--         >>= loadAndApplyTemplate "page.html" ctx
--         >>= relativizeAllUrls

  -- TODO remove atom feed now that firefox doesn't support them anymore?
  -- TODO how to relativizeUrls in here?
  whenAnyTagChanges $ create ["atom.xml"] $ do
    route idRoute
    compile $ do
      let feedCtx = (postCtx tags) <> bodyField "description"
      posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots postMd "content"
      posts' <- renderAtom myFeedConfig feedCtx posts
      -- return $ fmap (replace "SITEROOT" "") posts'
      return posts'

  -- index should look like recent.html on desktops,
  -- and like the aside with no content on mobile
  whenAnyTagChanges $ match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll postMd
      let ctx = recentCtx posts tags
      getResourceBody
        >>= applyAsTemplate ctx
        >>= relativizeAllUrls

  -- based on http://nbloomf.blog/site.html
  whenAnyTagChanges $ create ["404.html"] $ do
    route idRoute
    compile $ do
      let
        body = concat
          [ "<h1>404 - Not Found</h1>"
          , "<br/> Sorry! Maybe try <a href=\"/recent.html\">recent posts</a>?"
          ]
        ctx = mconcat
          [ constField "title" "404 - Not Found"
          , constField "body" body
          , postCtx tags
          ]
      makeItem ""
        >>= loadAndApplyTemplate "page.html" ctx
        >>= relativizeAllUrls

--------------------
-- per-post files --
--------------------

postDir = "posts/*/*/*/*"

postMd  = fromGlob $ postDir ++ "/index.md"
postPng = fromGlob $ postDir ++ "/*.png"
postJpg = fromGlob $ postDir ++ "/*.jpg"
postSvg = fromGlob $ postDir ++ "/*.svg"
postTar = fromGlob $ postDir ++ "/*.tar"
postSubdirs = fromGlob $ postDir ++ "/**/*" -- TODO is that ok?

----------------
-- root files --
----------------

rootFiles :: Pattern
rootFiles = fromList
  [ "robots.txt"
  , "favicon.ico"
  ]

-- this one is clunky, but correctly places files in the site root
toRoot :: Maybe String -> Routes
toRoot mExt = customRoute $ baseName . toFilePath
  where
    baseName  p = baseName' p ++ ext p
    baseName' p = if takeFileName p == "index.md"
                    then takeBaseName (takeDirectory p)
                    else takeBaseName p
    ext p = case mExt of
              Nothing -> takeExtension p
              Just e  -> "." ++ e

-- TODO fix this to work with urls relative to the current post
relativizeUrlsWith' :: String  -- ^ Path to the site root
                    -> String  -- ^ Path to the current page (including root)
                    -> String  -- ^ HTML to relativize
                    -> String  -- ^ Resulting HTML
relativizeUrlsWith' root path = withUrls rel
  where
    -- isRel x = "/" `isPrefixOf` x && not ("//" `isPrefixOf` x)
    rel x | "http" `isPrefixOf` x = x
    rel x |  "/" `isPrefixOf` x = root ++ x
    rel x | "./" `isPrefixOf` x = root ++ "/" ++ path ++ tail x
    rel x | otherwise = root ++ "/" ++ path ++ "/" ++ x
    -- rel x = if isRel x then root ++ x else x

-- based on hakyll's relativizeUrls
-- adds find-and-replace through all text so it works with js + css in addition to html
-- TODO get rid of the weird SITEROOT convention?
-- TODO make this work on urls relative to the current post too
relativizeAllUrls :: Item String -> Compiler (Item String)
relativizeAllUrls item = do
  route <- getRoute $ itemIdentifier item
  return $ case route of
    Nothing -> item
    Just r ->
      let rootPath = toSiteRoot r
          postDir  = takeDirectory r
      -- in fmap (replace "SITEROOT" rootPath)
      in fmap (relativizeUrlsWith' rootPath postDir) item

-- TODO how should this relate to Tags?
data WordList = WordList { list :: [(String, Int)] }
  deriving (Generic, Show, ToJSON)

-- 1. make a list of posts that use one of the query tags
-- 2. filter for tags that include one of those same posts
relatedTags :: Tags -> [String] -> Tags
relatedTags allTags queryTags = allTags { tagsMap = overlapMap }
  where
    allMap      = tagsMap allTags
    queryMap    = filter (\(s, _) -> s `elem` queryTags) allMap
    queryIdents = nub $ concat $ map snd queryMap
    overlapMap  = filter (\(_, is) -> not . null $ intersect is queryIdents) allMap

renderWordList :: WordList -> String
renderWordList = unpackChars . encode

-- base context which should include anything needed across the whole site
siteCtx :: Context String
siteCtx = defaultContext

indexCtx :: Tags -> Context String
indexCtx tags =
  tagCloudField "tagcloud" 60 200 tags
  <> siteCtx

recentCtx :: [Item String] -> Tags -> Context String
recentCtx posts tags = constField "title" "Recent"
  <> listField "posts" (postCtx tags) (return posts)
  -- <> constField "relatedtags" (renderWordList $ indexTags tags)
  <> tagCloudField "tagcloud" 60 200 tags
  <> siteCtx

-- TODO if the monad works, can just get tags too right?
postCtx :: Tags -> Context String
postCtx tags =
  dropIndexHtml "url" <>
  tagsField "tags" tags <>
  -- postTagsField "relatedtags" <> -- TODO remove?
  -- constField "relatedtags" (renderWordList $ postTags tags post) <>
  dateField "date" "%Y-%m-%d" <>
  tagCloudField "tagcloud" 60 200 tags <> -- TODO get related tags working here too
  siteCtx

tagsCtx :: [Item String] -> Tags -> String -> Context String
tagsCtx posts tags tag = constField "title" ("Posts tagged \"" ++ tag ++ "\":")
  <> constField "tag" tag
  <> listField "posts" (postCtx tags) (return posts)
  <> tagCloudField "tagcloud" 60 200 (relatedTags tags [tag]) -- works!
  <> siteCtx

myHakyllConfig :: Configuration
myHakyllConfig = defaultConfiguration
  { inMemoryCache        = True
  , providerDirectory    = "."
  , storeDirectory       = ".hakyll-cache"
  , destinationDirectory = "../.site"
  }

myFeedConfig :: FeedConfiguration
myFeedConfig = FeedConfiguration
  { feedTitle       = "Crypto Island"
  , feedDescription = "Crypto Island"          -- TODO blank?
  , feedAuthorName  = "jefdaj"               -- TODO blank?
  , feedAuthorEmail = "jefdaj@protonmail.ch" -- TODO blank?
  , feedRoot        = "https://cryptoisland.blog"
  }

-- based on https://github.com/vaclavsvejcar/svejcar-dev/blob/master/src/Site/Pandoc.hs
-- TODO load this from disk instead?
mkTemplate :: Bool -> Maybe String -> PT.Template T.Text
mkTemplate bToc mPic =
  let reminderTmpl = case mPic of
                  Just p  -> "<center class=\"reminder\"><img src=\"" `T.append` (T.pack p) `T.append` "\"></img></center>"
                  Nothing -> ""
      tocTmpl = if bToc
                  then "\n<div class=\"toc\"><div class=\"header\">Contents</div>\n$toc$\n" `T.append` reminderTmpl `T.append` "</div>"
                  else ""
      bodTmpl = "\n$body$"
      tmpl = tocTmpl `T.append` bodTmpl
  in case runIdentity $ PT.compileTemplate "" tmpl of
       Left  e -> error e
       Right t -> t

-- from https://argumatronic.com/posts/2018-01-16-pandoc-toc.html
-- and https://svejcar.dev/posts/2019/11/27/table-of-contents-in-hakyll/
withToc :: Maybe String -> WriterOptions
withToc mPic = defaultHakyllWriterOptions
  { writerTableOfContents = True
  , writerTOCDepth = 2
  , writerTemplate = Just $ mkTemplate True mPic
  }

withNoToc :: Maybe String -> WriterOptions
withNoToc mPic = defaultHakyllWriterOptions
  { writerTemplate = Just $ mkTemplate False mPic
  }

transform :: String -> String
transform url = case splitFileName url of
                    (p, "index.html") -> takeDirectory p
                    _                 -> url

dropIndexHtml :: String -> Context a
dropIndexHtml key = mapContext transform (urlField key) where
    transform url = case splitFileName url of
                        (p, "index.html") -> takeDirectory p
                        _                 -> url
