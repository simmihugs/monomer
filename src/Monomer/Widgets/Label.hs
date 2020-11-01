module Monomer.Widgets.Label (
  label,
  label_
) where

import Control.Applicative ((<|>))
import Data.Default
import Data.Maybe
import Data.Sequence (Seq)
import Data.Text (Text)

import qualified Data.Sequence as Seq
import qualified Data.Text as T

import Monomer.Widgets.Single

import qualified Monomer.Lens as L

data LabelCfg = LabelCfg {
  _lscTextOverflow :: Maybe TextOverflow,
  _lscMultiLine :: Maybe Bool
}

instance Default LabelCfg where
  def = LabelCfg {
    _lscTextOverflow = Nothing,
    _lscMultiLine = Nothing
  }

instance Semigroup LabelCfg where
  (<>) l1 l2 = LabelCfg {
    _lscTextOverflow = _lscTextOverflow l2 <|> _lscTextOverflow l1,
    _lscMultiLine = _lscMultiLine l2 <|> _lscMultiLine l1
  }

instance Monoid LabelCfg where
  mempty = def

instance OnTextOverflow LabelCfg where
  textEllipsis = def {
    _lscTextOverflow = Just Ellipsis
  }
  textClip = def {
    _lscTextOverflow = Just ClipText
  }

data LabelState = LabelState {
  _lstCaption :: Text,
  _lstCaptionFit :: Text
} deriving (Eq, Show)

label :: Text -> WidgetInstance s e
label caption = label_ caption def

label_ :: Text -> [LabelCfg] -> WidgetInstance s e
label_ caption configs = defaultWidgetInstance "label" widget where
  config = mconcat configs
  state = LabelState caption caption
  widget = makeLabel config state

makeLabel :: LabelCfg -> LabelState -> Widget s e
makeLabel config state = widget where
  widget = createSingle def {
    singleGetBaseStyle = getBaseStyle,
    singleMerge = merge,
    singleGetState = makeState state,
    singleGetSizeReq = getSizeReq,
    singleResize = resize,
    singleRender = render
  }

  textOverflow = fromMaybe Ellipsis (_lscTextOverflow config)
  LabelState caption captionFit = state

  getBaseStyle wenv inst = Just style where
    style = collectTheme wenv L.labelStyle

  merge wenv oldState inst = resultWidget newInstance where
    newState = fromMaybe state (useState oldState)
    newInstance = inst {
      _wiWidget = makeLabel config newState
    }

  getSizeReq wenv inst = sizeReq where
    style = activeStyle wenv inst
    Size w h = getTextSize wenv style caption
    factor = 1
    sizeReq = (FlexSize w factor, FixedSize h)

  resize wenv viewport renderArea inst = newInst where
    style = activeStyle wenv inst
    contentArea = fromMaybe def (removeOuterBounds style renderArea)
    (newCaptionFit, _) = case textOverflow of
      Ellipsis -> fitText wenv style contentArea caption
      _ -> (caption, def)
    newWidget
      | captionFit == newCaptionFit = _wiWidget inst
      | otherwise = makeLabel config (LabelState caption newCaptionFit)
    newInst = inst {
      _wiWidget = newWidget
    }

  render renderer wenv inst =
    drawStyledText_ renderer contentArea style captionFit
    where
      style = activeStyle wenv inst
      contentArea = getContentArea style inst
