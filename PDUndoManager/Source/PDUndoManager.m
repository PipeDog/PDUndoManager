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
    NSMutableArray *_stack; // Store action or action collection.
    
    BOOL _didOpenUndoGroup;
    NSMutableArray *_undoGroup;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _performPreviousActionRedoWhenUndo = NO;
        _index = -1;
        _stack = [NSMutableArray array];
        
        _didOpenUndoGroup = NO;
        _undoGroup = [NSMutableArray array];
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
    
    if (_didOpenUndoGroup) {
        [_undoGroup addObject:action];
    } else {
        [_stack addObject:action];
        _index ++;
    }
    
    if ([self.delegate respondsToSelector:@selector(didChangedIndexInUndoManager:)]) {
        [self.delegate didChangedIndexInUndoManager:self];
    }
}

- (void)removeAllActions {
    _index = -1;
    [_stack removeAllObjects];
    [_undoGroup removeAllObjects];
    
    if ([self.delegate respondsToSelector:@selector(didRemoveAllActionsInUndoManager:)]) {
        [self.delegate didRemoveAllActionsInUndoManager:self];
    }
    if ([self.delegate respondsToSelector:@selector(didChangedIndexInUndoManager:)]) {
        [self.delegate didChangedIndexInUndoManager:self];
    }
}

- (void)undo {
    NSAssert(!_didOpenUndoGroup, @"Must call `- endUndoGrouping` before undo!");
    
    if (_didOpenUndoGroup) {
        [self endUndoGrouping];
    }
    if (!self.canUndo) { return; }
    
    // Undo current action.
    BOOL currentIsUndoGroup = [_stack[_index] isKindOfClass:[NSArray class]];
    
    if (currentIsUndoGroup) {
        NSArray<id<PDUndoActionType>> *undoGroup = _stack[_index];

        [undoGroup enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<PDUndoActionType>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            !obj.undo ?: obj.undo();
        }];
    } else {
        id<PDUndoActionType> action = _stack[_index];
        !action.undo ?: action.undo();
    }
    
    // Update index.
    _index --;
    
    // Redo previous action if needed.
    if (_performPreviousActionRedoWhenUndo && _index >= 0) {
        BOOL prevIsUndoGroup = [_stack[_index] isKindOfClass:[NSArray class]];
        
        if (prevIsUndoGroup) {
            NSArray *undoGroup = _stack[_index];
            
            for (id<PDUndoActionType> action in undoGroup) {
                !action.redo ?: action.redo();
            }
        } else {
            id<PDUndoActionType> action = _stack[_index];
            !action.redo ?: action.redo();
        }
    }
    
    // Notify delegate.
    if (_index == -1 && [self.delegate respondsToSelector:@selector(didUndoAllActionsInUndoManager:)]) {
        [self.delegate didUndoAllActionsInUndoManager:self];
    }
    if ([self.delegate respondsToSelector:@selector(didChangedIndexInUndoManager:)]) {
        [self.delegate didChangedIndexInUndoManager:self];
    }
}

- (void)redo {
    NSAssert(!_didOpenUndoGroup, @"Must call `- endUndoGrouping` before redo!");
    
    if (_didOpenUndoGroup) {
        [self endUndoGrouping];
    }
    if (!self.canRedo) { return; }
    
    // Update index.
    _index ++;
    
    // Redo action.
    BOOL currentIsUndoGroup = [_stack[_index] isKindOfClass:[NSArray class]];
    
    if (currentIsUndoGroup) {
        NSArray *undoGroup = _stack[_index];
        
        for (id<PDUndoActionType> action in undoGroup) {
            !action.redo ?: action.redo();
        }
    } else {
        id<PDUndoActionType> action = _stack[_index];
        !action.redo ?: action.redo();
    }
    
    // Notify delegate.
    if ([self indexAtStackTop] && [self.delegate respondsToSelector:@selector(didRedoAllActionsInUndoManager:)]) {
        [self.delegate didRedoAllActionsInUndoManager:self];
    }
    if ([self.delegate respondsToSelector:@selector(didChangedIndexInUndoManager:)]) {
        [self.delegate didChangedIndexInUndoManager:self];
    }
}

- (void)beginUndoGrouping {
    if (_didOpenUndoGroup) {
        return;
    }
    
    _didOpenUndoGroup = YES;
}

- (void)endUndoGrouping {
    if (!_didOpenUndoGroup) {
        return;
    }
    
    _didOpenUndoGroup = NO;
    
    NSArray *undoGroup = [_undoGroup copy];
    if (undoGroup.count > 0) {
        [_stack addObject:undoGroup];
        _index ++;
    }
    
    [_undoGroup removeAllObjects];
    
    if ([self.delegate respondsToSelector:@selector(didChangedIndexInUndoManager:)]) {
        [self.delegate didChangedIndexInUndoManager:self];
    }
}

#pragma mark - Private Methods
- (void)removeDeprecatedActions {
    if ([self indexAtStackTop]) { return; }
    
    NSInteger count = _stack.count;
    NSInteger loc = _index + 1;
    NSInteger len = count - (_index + 1);
    
    if (len > 0) {
        NSRange range = NSMakeRange(loc, len);
        [_stack removeObjectsInRange:range];
    }
}

- (BOOL)indexAtStackTop {
    NSInteger count = _stack.count;
    return (_index == count - 1);
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
