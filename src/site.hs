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
import Data.List                      (intersect, isInfixOf)
import Data.Maybe                     (fromMaybe, fromJust)
import Data.Monoid                    ((<>))
import Data.String.Utils              (replace)
import GHC.Generics                   (Generic)
import Hakyll.Web.Html.RelativizeUrls (relativizeUrlsWith)
import Hakyll.Web.Tags                (tagsDependency)
import Text.Jasmine                   (minify)
import System.FilePath                (takeDirectory, takeBaseName, takeExtension)

import Hakyll.Images (loadImage, compressJpgCompiler)

main :: IO ()
main = hakyllWith myHakyllConfig $ do
  -- unique top-level files
  -- note that this excludes root/*.{png,jpg}
  match rootFiles $ route (toRoot Nothing) >> compile copyFileCompiler

  -- static files
  match ("*/*.png" .||. postPng) $ route idRoute >> compile copyFileCompiler
  match ("*/*.jpg" .||. postJpg) $ route idRoute >> compile (loadImage >>= compressJpgCompiler 50)
  match ("*.css" .||. "*/*.css") $ route (toRoot $ Just "css") >> compile compressCssCompiler

  -- html templates used below
  match ("*.html" .||. "*/*.html") $ compile templateCompiler

  -- top-level markdown pages: "about", "contact", "cv", etc.
  -- TODO why doesn't this create a file?
  match "*/index.md" $ do
    route (toRoot $ Just "html")
    compile $ pandocCompiler
      >>= loadAndApplyTemplate "site.html" defaultContext
      >>= relativizeAllUrls

  -- most of the rest is crudely updated whenever a tag changes
  tags <- buildTags postMd $ fromCapture "tags/*.html"
  let whenAnyTagChanges = rulesExtraDependencies [tagsDependency tags]

  -- posts (pandoc markdown)
  -- TODO would this ever need updating to deal with a tag change?
  match postMd $ do
    route $ setExtension "html"

    -- this part is from:
    -- https://argumatronic.com/posts/2018-01-16-pandoc-toc.html
    -- TODO separate compiler fn
    compile $ do
      ident <- getUnderlying
      toc   <- getMetadataField ident "toc"
      let readerSettings = defaultHakyllReaderOptions
          writerSettings = case toc of
            Just "true" -> withToc -- TODO True?
            _ -> defaultHakyllWriterOptions
      pandocCompilerWith readerSettings writerSettings
        >>= saveSnapshot "content" -- for the atom feed
        >>= loadAndApplyTemplate "posts/post.html" (postCtx tags)
        >>= loadAndApplyTemplate "site.html" (postCtx tags)
        >>= relativizeAllUrls

  tagsRules tags $ \tag pattern -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let ctx = tagCtx posts tags tag
        makeItem ""
          >>= loadAndApplyTemplate "tags/tag.html" ctx
          >>= loadAndApplyTemplate "site.html" ctx
          >>= relativizeAllUrls

  whenAnyTagChanges $ match "index/index.md" $ do
    route $ customRoute $ const "index.html"
    compile $ do
      posts <- recentFirst =<< loadAll postMd
      let ctx = recentCtx posts tags
      getResourceBody
        >>= applyAsTemplate ctx
        -- TODO factor out the centering stuff so it can be applied here
        >>= loadAndApplyTemplate "site.html" ctx
        >>= relativizeAllUrls

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

--------------------
-- per-post files --
--------------------

postDir = "posts/*/*/*/*"

postMd  = fromGlob $ postDir ++ "/index.md"
postPng = fromGlob $ postDir ++ "/*.png"
postJpg = fromGlob $ postDir ++ "/*.jpg"

----------------
-- root files --
----------------

rootFiles :: Pattern
rootFiles = fromList
  [ "root/CNAME"
  , "root/robots.txt"
  , "root/favicon.ico"
  ]

-- this one is clunky, but correctly places files in the site root
toRoot :: Maybe String -> Routes
toRoot mExt = customRoute $ baseName . toFilePath
  where
    baseName  p = baseName' p ++ ext p
    baseName' p = if "index" `isInfixOf` p
                    then takeBaseName (takeDirectory p)
                    else takeBaseName p
    ext p = case mExt of
              Nothing -> takeExtension p
              Just e  -> "." ++ e

-- based on hakyll's relativizeUrls
-- adds find-and-replace through all text so it works with js + css in addition to html
-- TODO get rid of the weird SITEROOT convention?
relativizeAllUrls :: Item String -> Compiler (Item String)
relativizeAllUrls item = do
  route <- getRoute $ itemIdentifier item
  return $ case route of
    Nothing -> item
    Just r ->
      let rootPath = toSiteRoot r
      -- in fmap (replace "SITEROOT" rootPath)
      in fmap (relativizeUrlsWith rootPath) item

data WordList = WordList { list :: [(String, Int)] }
  deriving (Generic, Show, ToJSON)

indexTags :: Tags -> WordList
indexTags tags = WordList { list = ("codeis.land", 1) : ("rss", 1) : counts }
  where
    counts' = concat $ replicate 3 $ counts -- TODO remove once more tags
    counts = map (\(t, is) -> (t, length is)) $ tagsMap tags

-- Starts from one tag and lists any others used in the same post(s)
-- 1. find posts that use the tag
-- 2. find tags that include one of those same posts
-- 3. pair tags with their normal post counts
tagTags :: Tags -> String -> WordList
tagTags tags tag = WordList { list = tagCounts }
  where
    mainMap     = tagsMap tags
    withMainTag = fromMaybe [] $ lookup tag mainMap
    overlapMap  = filter (\(_, is) -> not . null $ intersect is withMainTag) mainMap
    tagCounts   = map (\(t, is) -> (t, length is)) overlapMap

-- postTags :: MonadMetadata m => Identifier -> m String
-- postTags post = do
--     tags <- fmap concat . getTags
--     return $ renderWordList $ WordList { list = ("codeis.land", 1) : map (\t -> (t, 1)) tags }

-- postTags :: Tags -> Identifier -> WordList
-- postTags tags post = WordList { list = ("codeis.land", 1) : tagCounts }
--   where
--     relevant = filter (\(t, is) -> post `elem` is) $ tagsMap tags
--     tagCounts = map (\(t, is) -> (t, length is)) relevant

renderWordList :: WordList -> String
renderWordList = unpackChars . encode

-- TODO hey should be able to entirely get rid of this, no?
wordListCompiler :: Identifier -> WordList -> Compiler (Item String)
wordListCompiler iden words = do
  let item = Item iden $ unpackChars $ encode words
  unsafeCompiler $ return item

recentCtx :: [Item String] -> Tags -> Context String
recentCtx posts tags = constField "title" "Recent"
  <> listField "posts" (postCtx tags) (return posts)
  <> constField "wordlist" (renderWordList $ indexTags tags)
  <> defaultContext

-- TODO generalize to word lists for tag, index pages if possible
postTagsField :: String -> Context String
postTagsField key = field key $ \item -> do
  tags <- getTags $ itemIdentifier item
  let words = WordList { list = map (\t -> (t, 1)) tags }
  return $ renderWordList words

-- TODO if the monad works, can just get tags too right?
postCtx :: Tags -> Context String
postCtx tags =
  -- tagsField "tags" tags <>
  postTagsField "wordlist" <>
  -- constField "wordlist" (renderWordList $ postTags tags post) <>
  dateField "date" "%Y-%m-%d" <>
  defaultContext

tagCtx :: [Item String] -> Tags -> String -> Context String
tagCtx posts tags tag = constField "title" ("Posts tagged \"" ++ tag ++ "\"")
  <> constField "tag" tag 
  <> constField "wordlist" (renderWordList $ tagTags tags tag)
  <> listField "posts" (postCtx tags) (return posts)
  <> defaultContext

myHakyllConfig :: Configuration
myHakyllConfig = defaultConfiguration
  { inMemoryCache        = True
  , providerDirectory    = "."
  , storeDirectory       = ".hakyll-cache"
  , destinationDirectory = "../.site"
  }

myFeedConfig :: FeedConfiguration
myFeedConfig = FeedConfiguration
  { feedTitle       = "Code Island"
  , feedDescription = "Code Island"          -- TODO blank?
  , feedAuthorName  = "jefdaj"               -- TODO blank?
  , feedAuthorEmail = "jefdaj@protonmail.ch" -- TODO blank?
  , feedRoot        = "https://codeis.land"
  }

-- based on https://github.com/vaclavsvejcar/svejcar-dev/blob/master/src/Site/Pandoc.hs
-- TODO load this from disk instead?
tocTemplate :: PT.Template T.Text
tocTemplate =
  let tmpl = "\n<div class=\"toc\"><div class=\"header\">Contents</div>\n$toc$\n</div>\n$body$"
  in case runIdentity $ PT.compileTemplate "" tmpl of
       Left  e -> error e
       Right t -> t

-- from https://argumatronic.com/posts/2018-01-16-pandoc-toc.html
-- and https://svejcar.dev/posts/2019/11/27/table-of-contents-in-hakyll/
withToc :: WriterOptions
withToc = defaultHakyllWriterOptions
  { writerTableOfContents = True
  , writerTOCDepth = 2
  , writerTemplate = Just tocTemplate
  }
