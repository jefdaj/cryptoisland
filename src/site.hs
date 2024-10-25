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
import Data.List                      (intersect, isInfixOf, isPrefixOf, nub, delete)
import Data.Maybe                     (fromMaybe, fromJust)
import Data.Monoid                    ((<>))
import Data.String.Utils              (replace)
import GHC.Generics                   (Generic)
import Hakyll.Web.Html.RelativizeUrls (relativizeUrlsWith)
import Hakyll.Web.Tags                (tagsDependency)
import Hakyll.Web.Sass                (sassCompiler)
import Text.Jasmine                   (minify)
import System.FilePath (takeDirectory, takeBaseName, takeFileName, takeExtension, splitFileName)

import Hakyll.Images (loadImage, compressJpgCompiler)

main :: IO ()
main = hakyllWith myHakyllConfig $ do
  -- unique top-level files
  -- note that this excludes root/*.{png,jpg}
  match rootFiles $ route (toRoot Nothing) >> compile copyFileCompiler

  -- static files
  let staticPng = "*/*.png" .||. postPng
      staticJpg = "*/*.jpg" .||. postJpg
      sassFiles = "*.scss" .||. "*/*.scss"
      staticSvg =
        ("*/*.svg" .||. postSvg) .&&.
        complement ("*/island*.svg" .||. "aside/boat.svg")
      toCopy =
        staticSvg .||.
        staticPng .||.
        postTar .||.
        postSubdirs .||.
        "about/jefdaj.asc" .||.
        "variables.scss"

  match toCopy    $ route idRoute >> compile copyFileCompiler
  match staticJpg $ route idRoute >> compile (loadImage >>= compressJpgCompiler 50)
  match sassFiles $ route (toRoot $ Just "css") >> compile (fmap compressCss <$> sassCompiler)

  -- html templates used below
  -- note that we treat svg as html here because it includes clickable links
  -- TODO does that contribute to it being removed from Tor Browser?
  let templates =
        "page.html" .||.
        "posts.html" .||.
        "*/*.html" .||.
        "*/island*.svg" .||.
        "aside/boat.svg"
  match templates $ compile templateCompiler

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
      reminder <- getMetadataField ident "reminder"
      toc      <- getMetadataField ident "toc"
      postTags <- getTags ident
      let readerSettings = defaultHakyllReaderOptions
          writerSettings = case toc of
            Just "false" -> withNoToc reminder
            Just "False" -> withNoToc reminder
            _ -> withToc reminder -- default to adding it unless explicitly false
      pandocCompilerWith readerSettings writerSettings
        >>= saveSnapshot "content" -- for the atom feed
        >>= loadAndApplyTemplate "posts/post.html" (postCtx tags $ Just postTags)
        >>= loadAndApplyTemplate "page.html"       (postCtx tags $ Just postTags)
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
      let ctx = constField "title" "Home" <>
                recentCtx posts tags <>
                constField "extracss" "./index.css"
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
        postTags <- fmap (nub . concat) $ mapM getTags $ map itemIdentifier posts
        let ctx = tagsCtx posts tags tag postTags
        makeItem ""
          >>= loadAndApplyTemplate "tags/tag.html" ctx
          >>= loadAndApplyTemplate "page.html" ctx
          >>= relativizeAllUrls

  -- TODO remove atom feed now that firefox doesn't support them anymore?
  -- TODO how to relativizeUrls in here?
  whenAnyTagChanges $ create ["atom.xml"] $ do
    route idRoute
    compile $ do
      let feedCtx = (postCtx tags Nothing) <> bodyField "description"
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
          , postCtx tags Nothing
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

-- filter the tags map to include a specific list of tags only
filterTags :: Tags -> [String] -> Tags
filterTags allTags queryTags = allTags { tagsMap = matches }
  where
    matches = filter (\(s, _) -> s `elem` queryTags) $ tagsMap allTags

-- 1. make a list of posts that use one of the query tags
-- 2. filter for tags that include one of those same posts
relatedTags :: Tags -> Maybe [String] -> Tags
relatedTags allTags Nothing = allTags
relatedTags allTags (Just queryTags) = allTags { tagsMap = overlapMap }
  where
    allMap      = tagsMap allTags
    queryMap    = filter (\(s, _) -> s `elem` queryTags) allMap
    queryIdents = nub $ concat $ map snd queryMap
    overlapMap  = filter keep allMap
    keep (s, is) = (s `elem` queryTags) ||
                   (not $ null $ intersect is queryIdents)

-- base context which should include anything needed across the whole site
siteCtx :: Context String
siteCtx = defaultContext

indexCtx :: Tags -> Context String
indexCtx tags =
  tagCloudField "tagcloud" 77 175 tags
  <> siteCtx

-- TODO why do certain min:max font size ratios cause a chrome memory leak??

recentCtx :: [Item String] -> Tags -> Context String
recentCtx posts tags = constField "title" "Recent"
  <> listField "posts" (postCtx tags Nothing) (return posts)
  <> tagCloudField "tagcloud" 50 155 tags
  <> siteCtx

postCtx :: Tags -> Maybe [String] -> Context String
postCtx tags postTags =
  dropIndexHtml "url" <>
  tagsField "tags" tags <>
  dateField "date" "%Y-%m-%d" <>
  tagCloudField "tagcloud" 60 165 (relatedTags tags postTags) <>
  siteCtx

tagsCtx :: [Item String] -> Tags -> String -> [String] -> Context String
tagsCtx posts tags mainTag postTags =
     constField "title" ("Posts tagged \"" ++ mainTag ++ "\":")
  <> constField "tag" mainTag
  <> listField "posts" (postCtx tags Nothing) (return posts)
  <> tagCloudField "tagcloud" 70 175 (filterTags tags $ delete mainTag postTags)
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
  , feedDescription = "Crypto Island"        -- TODO blank?
  , feedAuthorName  = "jefdaj"               -- TODO blank?
  , feedAuthorEmail = "jefdaj@protonmail.ch" -- TODO blank?
  , feedRoot        = "https://cryptoisland.blog"
  }

-- based on https://github.com/vaclavsvejcar/svejcar-dev/blob/master/src/Site/Pandoc.hs
-- TODO load this from disk instead?
mkTemplate :: Bool -> Maybe String -> PT.Template T.Text
mkTemplate bToc mPic =
  let reminderTmpl = case mPic of
                  Nothing -> ""
                  Just p  ->
                    "<center class=\"reminder\"><img src=\"" <>
                    T.pack p <>
                    "\"></img></center>"
      tocTmpl = if bToc
                  then
                    "\n<div class=\"toc\"><div class=\"header\">Contents</div>\n$toc$\n" <>
                    reminderTmpl <>
                    "</div>"
                  else
                    "\n<div class=\"toc\">\n" <>
                    reminderTmpl <>
                    "</div>"
      bodTmpl = "\n$body$"
      tmpl = tocTmpl <> bodTmpl
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
