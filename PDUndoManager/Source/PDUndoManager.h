//
//  PDUndoManager.h
//  PDUndoManager
//
//  Created by liang on 2019/11/29.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PDUndoManager;

NS_ASSUME_NONNULL_BEGIN

@protocol PDUndoAction <NSObject>

@property (nonatomic, copy) void (^redo)(void);
@property (nonatomic, copy) void (^undo)(void);

@end

@protocol PDUndoManagerDelegate <NSObject>

@optional
- (void)didRemoveAllActionsInUndoManager:(PDUndoManager *)undoManager;
- (void)didUndoAllActionsInUndoManager:(PDUndoManager *)undoManager;
- (void)didRedoAllActionsInUndoManager:(PDUndoManager *)undoManager;
- (void)didChangedIndexInUndoManager:(PDUndoManager *)undoManager;

@end

@interface PDUndoManager : NSObject

@property (nonatomic, weak) id<PDUndoManagerDelegate> delegate;

@property (readonly) BOOL canUndo;
@property (readonly) BOOL canRedo;

- (void)performPreviousActionRedoWhenUndo:(BOOL)yesOrNo;

- (void)addAction:(id<PDUndoAction>)action;
- (void)removeAllActions;

- (void)undo;
- (void)redo;

- (void)beginUndoGrouping;
- (void)endUndoGrouping;

@end

NS_ASSUME_NONNULL_END
