module Halogen.Try where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen.Aff as HA
import Halogen.HTML (HTML)
import Halogen.Component (Component)
import Halogen.VDom.Driver (runUI)
import Partial.Unsafe (unsafeCrashWith)
import Web.DOM.ParentNode (QuerySelector(..))

main :: forall f i o. Component HTML f i o Aff -> i -> Effect Unit
main component s = HA.runHalogenAff do
    mappElem <- HA.selectElement $ QuerySelector "#app"
    case mappElem of
      Nothing -> unsafeCrashWith "div#app has to be defined"
      Just appElem -> runUI component s appElem
