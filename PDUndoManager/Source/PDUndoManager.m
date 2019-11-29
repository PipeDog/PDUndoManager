//
//  PDUndoManager.m
//  PDUndoManager
//
//  Created by liang on 2019/11/29.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDUndoManager.h"

@implementation PDUndoManager {
    BOOL _performPreviousActionRedoWhenUndo;
    NSInteger _index;
    NSMutableArray<id<PDUndoActionType>> *_stack;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _index = -1;
        _stack = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public Methods
- (void)performPreviousActionRedoWhenUndo:(BOOL)yesOrNo {
    _performPreviousActionRedoWhenUndo = yesOrNo;
}

- (void)addAction:(id<PDUndoActionType>)action {
    if (!action) { return; }
    
    if (![self indexAtStackTop]) {
        [self removeDeprecatedActions];
    }
    
    [_stack addObject:action];
    _index ++;
}

- (void)undo {
    if (!self.canUndo) { return; }
    
    id<PDUndoActionType> action = _stack[_index];
    !action.undo ?: action.undo();
    
    _index --;
    
    if (_performPreviousActionRedoWhenUndo) {
        action = _stack[_index];
        !action.redo ?: action.redo();
    }
    
    if (_index == -1 && [self.delegate respondsToSelector:@selector(didUndoAllActionsInUndoManager:)]) {
        [self.delegate didUndoAllActionsInUndoManager:self];
    }
}

- (void)redo {
    if (!self.canRedo) { return; }
    
    _index ++;
    
    id<PDUndoActionType> action = _stack[_index];
    !action.redo ?: action.redo();
    
    if ([self indexAtStackTop] && [self.delegate respondsToSelector:@selector(didRedoAllActionsInUndoManager:)]) {
        [self.delegate didRedoAllActionsInUndoManager:self];
    }
}

- (void)removeAllActions {
    _index = -1;
    [_stack removeAllObjects];
    
    if ([self.delegate respondsToSelector:@selector(didRemoveAllActionsInUndoManager:)]) {
        [self.delegate didRemoveAllActionsInUndoManager:self];
    }
}

#pragma mark - Private Methods
- (void)removeDeprecatedActions {
    if ([self indexAtStackTop]) { return; }
    
    NSInteger loc = _index + 1;
    NSInteger len = _stack.count - (_index + 1);
    NSRange range = NSMakeRange(loc, len);
    [_stack removeObjectsInRange:range];
}

- (BOOL)indexAtStackTop {
    return (_index == _stack.count - 1);
}

#pragma mark - Getter Methods
- (BOOL)canUndo {
    if (_index < 0) { return NO; }
    if (!_stack.count) { return NO; }
    
    return YES;
}

- (BOOL)canRedo {
    if (!_stack.count) { return NO; }
    if ([self indexAtStackTop]) { return NO; }
    
    return YES;
}

@end
