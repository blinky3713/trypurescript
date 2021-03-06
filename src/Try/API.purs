module Try.API
  ( ErrorPosition(..)
  , CompilerError(..)
  , CompileError(..)
  , CompileWarning(..)
  , Suggestion(..)
  , SuccessResult(..)
  , FailedResult(..)
  , CompileResult(..)
  , Backend(..)
  , BackendConfig(..)
  , getBackendConfig
  , getBackendConfigFromString
  ) where

import Prelude

import Control.Alt ((<|>))
import Control.Monad.Cont.Trans (ContT(ContT))
import Control.Monad.Except (runExcept)
import Control.Monad.Except.Trans (ExceptT(ExceptT))
import Control.Parallel (parTraverse)
import Data.Array (intercalate)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.List.NonEmpty (NonEmptyList)
import Data.Maybe (Maybe)
import Data.String.Regex (replace)
import Data.String.Regex.Flags (global)
import Data.String.Regex.Unsafe (unsafeRegex)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn3, EffectFn4, mkEffectFn1, runEffectFn3, runEffectFn4)
import Foreign (Foreign, ForeignError)
import Foreign.Class (class Decode, decode)
import Foreign.Generic (defaultOptions, genericDecode)
import Foreign.Generic.Types (Options, SumEncoding(..))
import Partial.Unsafe (unsafePartial)
import Try.Types (JS(JS))

decodingOptions :: Options
decodingOptions = defaultOptions { unwrapSingleConstructors = true }

-- | The range of text associated with an error
newtype ErrorPosition = ErrorPosition
  { startLine :: Int
  , endLine :: Int
  , startColumn :: Int
  , endColumn :: Int
  }

derive instance genericErrorPosition :: Generic ErrorPosition _

instance decodeErrorPosition :: Decode ErrorPosition where
  decode = genericDecode decodingOptions

newtype CompilerError = CompilerError
  { message :: String
  , position :: Maybe ErrorPosition
  }

derive instance genericCompilerError :: Generic CompilerError _

instance decodeCompilerError :: Decode CompilerError where
  decode = genericDecode decodingOptions

-- | An error reported from the compile API.
data CompileError
  = CompilerErrors (Array CompilerError)
  | OtherError String

derive instance genericCompileError :: Generic CompileError _

instance decodeCompileError :: Decode CompileError where
  decode = genericDecode
    (defaultOptions
      { sumEncoding =
          TaggedObject
            { tagFieldName: "tag"
            , contentsFieldName: "contents"
            , constructorTagTransform: identity
            }
      })

newtype Suggestion = Suggestion
  { replacement :: String
  , replaceRange :: Maybe ErrorPosition
  }

derive instance genericSuggestion :: Generic Suggestion _

instance decodeSuggestion :: Decode Suggestion where
  decode = genericDecode decodingOptions

newtype CompileWarning = CompileWarning
  { errorCode :: String
  , message :: String
  , position :: Maybe ErrorPosition
  , suggestion :: Maybe Suggestion
  }

derive instance genericCompileWarning :: Generic CompileWarning _

instance decodeCompileWarning :: Decode CompileWarning where
  decode = genericDecode decodingOptions

newtype SuccessResult = SuccessResult
  { js :: String
  , warnings :: Maybe (Array CompileWarning)
  }

derive instance genericSuccessResult :: Generic SuccessResult _

instance decodeSuccessResult :: Decode SuccessResult where
  decode = genericDecode decodingOptions

newtype FailedResult = FailedResult
  { error :: CompileError }

derive instance genericFailedResult :: Generic FailedResult _

instance decodeFailedResult :: Decode FailedResult where
  decode = genericDecode decodingOptions

-- | The result of calling the compile API.
data CompileResult
  = CompileSuccess SuccessResult
  | CompileFailed FailedResult

-- | Parse the result from the compile API and verify it
instance decodeCompileResult :: Decode CompileResult where
  decode f =
    CompileSuccess <$> genericDecode decodingOptions f
    <|> CompileFailed <$> genericDecode decodingOptions f

foreign import get_
  :: EffectFn3
            String
            (EffectFn1 String Unit)
            (EffectFn1 String Unit)
            Unit

-- | A wrapper for `get` which uses `ContT`.
get :: String -> ExceptT String (ContT Unit Effect) String
get uri = ExceptT (ContT \k -> runEffectFn3 get_ uri (mkEffectFn1 (k <<< Right)) (mkEffectFn1 (k <<< Left)))

-- | Get the default bundle
getDefaultBundle
  :: String
  -> ExceptT String (ContT Unit Effect) JS
getDefaultBundle endpoint = JS <$> get (endpoint <> "/bundle")

-- | Get the JS bundle for the Thermite backend, which includes additional dependencies
getThermiteBundle
  :: String
  -> ExceptT String (ContT Unit Effect) JS
getThermiteBundle endpoint =
  let getAll = parTraverse get
        [ "js/console.js"
        , "js/react.min.js"
        , "js/react-dom.min.js"
        , endpoint <> "/bundle"
        ]

      onComplete :: Partial
                 => Array String
                 -> JS
      onComplete [consoleScript, react, react_dom, bundle] =
        let replaced = bundle
                         # replace (unsafeRegex """require\("react"\)""" global) "window.React"
                         # replace (unsafeRegex """require\("react-dom"\)""" global) "window.ReactDOM"
                         # replace (unsafeRegex """require\("react-dom\/server"\)""" global) "window.ReactDOM"
        in JS (intercalate "\n" [consoleScript, react, react_dom, replaced])
  in unsafePartial onComplete <$> getAll

-- | POST the specified code to the Try PureScript API, and wait for
-- | a response.
foreign import compile_
  :: EffectFn4
            String
            String
            (EffectFn1 Foreign Unit)
            (EffectFn1 String Unit)
            Unit

-- | A wrapper for `compileApi` which uses `ContT`.
compile
  :: String
  -> String
  -> ExceptT String (ContT Unit Effect)
       (Either (NonEmptyList ForeignError) CompileResult)
compile endpoint code = ExceptT (ContT \k -> runEffectFn4 compile_ endpoint code (mkEffectFn1 (k <<< Right <<< runExcept <<< decode)) (mkEffectFn1 (k <<< Left)))

newtype BackendConfig = BackendConfig
  { backend       :: String
  , mainGist      :: String
  , extra_styling :: String
  , extra_body    :: String
  , compile       :: String
                  -> ExceptT String (ContT Unit Effect)
                       (Either (NonEmptyList ForeignError) CompileResult)
  , getBundle     :: ExceptT String (ContT Unit Effect) JS
  }

data Backend
  = Core
  | Halogen
  | Behaviors

backendFromString :: Partial => String -> Backend
backendFromString "core"      = Core
backendFromString "halogen"  = Halogen
backendFromString "behaviors" = Behaviors

backendToString :: Backend -> String
backendToString Core      = "core"
backendToString Halogen  = "halogen"
backendToString Behaviors = "behaviors"

derive instance eqBackend :: Eq Backend
derive instance ordBackend :: Ord Backend

getBackendConfig :: Backend -> String -> BackendConfig
getBackendConfig be url = case be of
  Core -> BackendConfig
    { backend: "core"
    , mainGist: "cf77cdb33df8760d4648be0552654982"
    , extra_styling: ""
    , extra_body: ""
    , compile: compile url
    , getBundle: getDefaultBundle url
    }
  Halogen ->  BackendConfig
    { backend: "halogen"
    , mainGist: "cf77cdb33df8760d4648be0552654982"
    , extra_styling: """<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">"""
    , extra_body: """<div id="app"></div>"""
    , compile: compile url
    , getBundle: getThermiteBundle url
    }
  Behaviors -> BackendConfig
    { backend: "behaviors"
    , mainGist: "cf77cdb33df8760d4648be0552654982"
    , extra_styling: ""
    , extra_body: """<canvas id="canvas" width="800" height="600"></canvas>"""
    , compile: compile url
    , getBundle: getDefaultBundle url
    }

getBackendConfigFromString :: String -> String -> BackendConfig
getBackendConfigFromString s = getBackendConfig (unsafePartial backendFromString s)
