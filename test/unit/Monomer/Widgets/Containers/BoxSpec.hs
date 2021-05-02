{-# LANGUAGE FlexibleContexts #-}

module Monomer.Widgets.Containers.BoxSpec (spec) where

import Control.Lens ((&), (^.), (.~))
import Data.Text (Text)
import Data.Typeable (Typeable)
import Test.Hspec

import qualified Data.Sequence as Seq

import Monomer.Core
import Monomer.Core.Combinators
import Monomer.Event
import Monomer.TestEventUtil
import Monomer.TestUtil
import Monomer.Widgets.Containers.Box
import Monomer.Widgets.Containers.ZStack
import Monomer.Widgets.Singles.Button
import Monomer.Widgets.Singles.Label

import qualified Monomer.Lens as L

newtype BtnEvent
  = BtnClick Int
  deriving (Eq, Show)

spec :: Spec
spec = describe "Box" $ do
  handleEvent
  handleEventIgnoreEmpty
  handleEventSinkEmpty
  getSizeReq
  getSizeReqUpdater
  resize

handleEvent :: Spec
handleEvent = describe "handleEvent" $ do
  it "should not generate an event if clicked outside" $
    events (Point 3000 3000) `shouldBe` Seq.empty

  it "should generate an event if the button (centered) is clicked" $
    events (Point 320 240) `shouldBe` Seq.singleton (BtnClick 0)

  where
    wenv = mockWenv ()
    btn = button "Click" (BtnClick 0)
    boxNode = nodeInit wenv (box btn)
    events p = nodeHandleEventEvts wenv [evtClick p] boxNode

handleEventIgnoreEmpty :: Spec
handleEventIgnoreEmpty = describe "handleEventIgnoreEmpty" $ do
  it "should click the bottom layer, since nothing is handled on top" $
    clickIgnored (Point 200 15) `shouldBe` Seq.singleton (BtnClick 1)

  it "should click the top layer, since pointer is on the button" $
    clickIgnored (Point 320 240) `shouldBe` Seq.singleton (BtnClick 2)

  where
    wenv = mockWenv ()
    btn2 = button "Click 2" (BtnClick 2) `style` [height 10]
    ignoredNode = zstack_ [onlyTopActive False] [
        button "Click 1" (BtnClick 1),
        box_ [ignoreEmptyArea_ True] btn2
      ]
    clickIgnored p = nodeHandleEventEvts wenv [evtClick p] ignoredNode

handleEventSinkEmpty :: Spec
handleEventSinkEmpty = describe "handleEventSinkEmpty" $ do
  it "should do nothing, since event is not passed down" $
    clickSunk (Point 200 15) `shouldBe` Seq.empty

  it "should click the top layer, since pointer is on the button" $
    clickSunk (Point 320 240) `shouldBe` Seq.singleton (BtnClick 2)

  where
    wenv = mockWenv ()
    centeredBtn = button "Click 2" (BtnClick 2) `style` [height 10]
    sunkNode = zstack_ [onlyTopActive False] [
        button "Click 1" (BtnClick 1),
        box_ [ignoreEmptyArea_ False] centeredBtn
      ]
    clickSunk p = nodeHandleEventEvts wenv [evtClick p] sunkNode

getSizeReq :: Spec
getSizeReq = describe "getSizeReq" $ do
  it "should return width = Fixed 50" $
    sizeReqW `shouldBe` fixedSize 50

  it "should return height = Fixed 20" $
    sizeReqH `shouldBe` fixedSize 20

  where
    wenv = mockWenvEvtUnit ()
    boxNode = box (label "Label")
    (sizeReqW, sizeReqH) = nodeGetSizeReq wenv boxNode

getSizeReqUpdater :: Spec
getSizeReqUpdater = describe "getSizeReqUpdater" $ do
  it "should return width = Min 50 2" $
    sizeReqW `shouldBe` minSize 50 2

  it "should return height = Max 20" $
    sizeReqH `shouldBe` maxSize 20 3

  where
    wenv = mockWenvEvtUnit ()
    updater (rw, rh) = (minSize (rw ^. L.fixed) 2, maxSize (rh ^. L.fixed) 3)
    boxNode = box_ [sizeReqUpdater updater] (label "Label")
    (sizeReqW, sizeReqH) = nodeGetSizeReq wenv boxNode

resize :: Spec
resize = describe "resize" $ do
  resizeDefault
  resizeExpand
  resizeAlign

resizeDefault :: Spec
resizeDefault = describe "default" $ do
  it "should have the provided viewport size" $
    viewport `shouldBe` vp

  it "should have one child" $
    children `shouldSatisfy` (== 1) . Seq.length

  it "should have its children assigned a viewport" $
    cViewport `shouldBe` cvp

  where
    wenv = mockWenvEvtUnit ()
    vp  = Rect   0   0 640 480
    cvp = Rect 295 230  50  20
    boxNode = box (label "Label")
    newNode = nodeInit wenv boxNode
    children = newNode ^. L.children
    viewport = newNode ^. L.info . L.viewport
    cViewport = getChildVp wenv []

resizeExpand :: Spec
resizeExpand = describe "expand" $
  it "should have its children assigned a valid viewport" $
    cViewport `shouldBe` vp

  where
    wenv = mockWenvEvtUnit ()
    vp  = Rect   0   0 640 480
    cViewport = getChildVp wenv [expandContent]

resizeAlign :: Spec
resizeAlign = describe "align" $ do
  it "should align its child left" $
    childVpL `shouldBe` cvpl

  it "should align its child right" $
    childVpR `shouldBe` cvpr

  it "should align its child top" $
    childVpT `shouldBe` cvpt

  it "should align its child bottom" $
    childVpB `shouldBe` cvpb

  it "should align its child top-left" $
    childVpTL `shouldBe` cvplt

  it "should align its child bottom-right" $
    childVpBR `shouldBe` cvpbr

  where
    wenv = mockWenvEvtUnit ()
    cvpl  = Rect   0 230 50 20
    cvpr  = Rect 590 230 50 20
    cvpt  = Rect 295   0 50 20
    cvpb  = Rect 295 460 50 20
    cvplt = Rect   0   0 50 20
    cvpbr = Rect 590 460 50 20
    childVpL = getChildVp wenv [alignLeft]
    childVpR = getChildVp wenv [alignRight]
    childVpT = getChildVp wenv [alignTop]
    childVpB = getChildVp wenv [alignBottom]
    childVpTL = getChildVp wenv [alignTop, alignLeft]
    childVpBR = getChildVp wenv [alignBottom, alignRight]

getChildVp :: (Eq s, Typeable e) => WidgetEnv s e -> [BoxCfg s e] -> Rect
getChildVp wenv cfgs = childLC ^. L.info . L.viewport where
  lblNode = label "Label"
  boxNodeLC = nodeInit wenv (box_ cfgs lblNode)
  childLC = Seq.index (boxNodeLC ^. L.children) 0