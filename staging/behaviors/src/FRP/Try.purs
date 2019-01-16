module FRP.Try (defaultMain) where

import Prelude

import Effect (Effect)
import Data.Foldable (for_)
import FRP.Behavior (Behavior, animate)
import Graphics.Canvas (getCanvasElementById, getContext2D)
import Graphics.Drawing (Drawing, render)

defaultMain :: Behavior Drawing -> Effect Unit
defaultMain b = do
  canvas <- getCanvasElementById "canvas"
  for_ canvas \c -> do
    ctx <- getContext2D c
    animate b (render ctx)
