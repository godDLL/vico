#import "ViMarkManager.h"
#import "ViCommon.h"
#include "logging.h"

@implementation ViMarkGroup

+ (ViMarkGroup *)markGroupWithSelector:(SEL)aSelector
{
	return [[ViMarkGroup alloc] initWithSelector:aSelector];
}

- (ViMarkGroup *)initWithSelector:(SEL)aSelector
{
	if ((self = [super init]) != nil) {
		groupSelector = aSelector;
		groups = [NSMutableDictionary dictionary];
		DEBUG(@"created group %@", self);
	}
	return self;
}

- (NSString *)attribute
{
	return NSStringFromSelector(groupSelector);
}

- (NSArray *)groups
{
	return [groups allValues];
}

- (void)rebuildFromMarks:(NSArray *)marks
{
	[self willChangeValueForKey:@"groups"];
	[self clear];
	for (ViMark *mark in marks)
		[self addMark:mark];
	[self didChangeValueForKey:@"groups"];

	DEBUG(@"grouped by attribute %@: %@", [self attribute], [self groups]);
}

- (void)addMark:(ViMark *)mark
{
	id key = nil;
	if ([mark respondsToSelector:groupSelector])
		key = [mark performSelector:groupSelector];
	if (key == nil)
		key = [NSNull null];
	ViMarkList *group = [groups objectForKey:key];
	if (group == nil) {
		[self willChangeValueForKey:@"groups"];
		group = [ViMarkList markListWithIdentifier:key];
		[groups setObject:group forKey:key];
		[self didChangeValueForKey:@"groups"];
	}
	[group addMark:mark];
}

- (void)addMarksFromArray:(NSArray *)marksToAdd
{
	NSMapTable *groupsToAdd = [NSMapTable mapTableWithWeakToStrongObjects];
	BOOL didAddGroup = NO;
	for (ViMark *mark in marksToAdd) {
		id key = nil;
		if ([mark respondsToSelector:groupSelector])
			key = [mark performSelector:groupSelector];
		if (key == nil)
			key = [NSNull null];
		ViMarkList *group = [groups objectForKey:key];
		if (group == nil) {
			if (!didAddGroup) {
				[self willChangeValueForKey:@"groups"];
				didAddGroup = YES;
			}
			group = [ViMarkList markListWithIdentifier:key];
			[groups setObject:group forKey:key];
		}

		NSMutableArray *addArray = [groupsToAdd objectForKey:group];
		if (addArray == nil) {
			addArray = [NSMutableArray arrayWithObject:mark];
			[groupsToAdd setObject:addArray forKey:group];
		} else
			[addArray addObject:mark];
	}
	for (ViMarkList *group in groupsToAdd)
		[group addMarksFromArray:[groupsToAdd objectForKey:group]];
	if (didAddGroup)
		[self didChangeValueForKey:@"groups"];
}

- (void)removeMark:(ViMark *)mark
{
	id key = nil;
	if ([mark respondsToSelector:groupSelector])
		key = [mark performSelector:groupSelector];
	if (key == nil)
		key = [NSNull null];
	ViMarkList *group = [groups objectForKey:key];
	[group removeMark:mark];
	if ([[group marks] count] == 0) {
		[self willChangeValueForKey:@"groups"];
		[groups removeObjectForKey:key];
		[self didChangeValueForKey:@"groups"];
	}
}

- (void)clear
{
	[self willChangeValueForKey:@"groups"];
	[groups removeAllObjects];
	[self didChangeValueForKey:@"groups"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ViMarkGroup by %@ (%lu groups)>",
		[self attribute], [[self groups] count]];
}

@end




@implementation ViMarkList

@synthesize marks;

+ (ViMarkList *)markListWithIdentifier:(id)anIdentifier
{
	return [[ViMarkList alloc] initWithIdentifier:anIdentifier];
}

+ (ViMarkList *)markList
{
	return [[ViMarkList alloc] init];
}

- (ViMarkList *)initWithIdentifier:(id)anIdentifier
{
	if ((self = [super init]) != nil) {
		identifier = anIdentifier;
		marks = [NSMutableArray array];
		marksByName = [NSMutableDictionary dictionary];
		groups = [NSMutableDictionary dictionary];
		currentIndex = NSNotFound;
	}
	return self;
}

- (ViMarkList *)init
{
	return [self initWithIdentifier:nil];
}

- (void)eachGroup:(void (^)(ViMarkGroup *))callback
{
	for (ViMarkGroup *group in [groups allValues]) {
		callback(group);
	}
}

- (void)clear
{
	[self willChangeValueForKey:@"marks"];
	[marks removeAllObjects];
	[marksByName removeAllObjects];
	[self didChangeValueForKey:@"marks"];

	[self eachGroup:^(ViMarkGroup *group) { [group clear]; }];
}

- (void)addMark:(ViMark *)mark
{
	NSUInteger lastIndex = [marks count];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:lastIndex];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];
	if (mark.name) {
		ViMark *oldMark = [marksByName objectForKey:mark.name];
		if (oldMark) {
			[marks removeObject:oldMark]; // XXX: linear search!
			[self eachGroup:^(ViMarkGroup *group) { [group removeMark:oldMark]; }];
		}
		[marksByName setObject:mark forKey:mark.name];
	}
	[marks addObject:mark];
	[mark registerList:self];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];

	[self eachGroup:^(ViMarkGroup *group) { [group addMark:mark]; }];
}

- (void)addMarksFromArray:(NSArray *)marksToAdd
{
	NSUInteger numToAdd = [marksToAdd count];
	if (numToAdd == 0)
		return;

	NSUInteger lastIndex = [marks count];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex, numToAdd)];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];
	for (ViMark *mark in marksToAdd) {
		if (mark.name) {
			ViMark *oldMark = [marksByName objectForKey:mark.name];
			if (oldMark)
				[marks removeObject:oldMark]; // XXX: linear search!
			[marksByName setObject:mark forKey:mark.name];
		}
		[mark registerList:self];
	}
	[marks addObjectsFromArray:marksToAdd];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];

	[self eachGroup:^(ViMarkGroup *group) { [group addMarksFromArray:marksToAdd]; }];
}

- (void)removeMark:(ViMark *)mark
{
	NSUInteger index = [marks indexOfObject:mark]; // XXX: linear search!
	if (index == NSNotFound)
		return;

	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];
	[marks removeObjectAtIndex:index];
	if (mark.name)
		[marksByName removeObjectForKey:mark.name];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"marks"];

	[self eachGroup:^(ViMarkGroup *group) { [group removeMark:mark]; }];
}

- (ViMark *)lookup:(NSString *)aName
{
	return [marksByName objectForKey:aName];
}

- (NSUInteger)count
{
	return [marks count];
}

- (ViMarkGroup *)groupBy:(NSString *)selectorString
{
	ViMarkGroup *group = [groups objectForKey:selectorString];
	if (group == nil) {
		group = [ViMarkGroup markGroupWithSelector:NSSelectorFromString(selectorString)];
		[group rebuildFromMarks:marks];
		[groups setObject:group forKey:selectorString];
	}
	DEBUG(@"returning group %@", group);
	return group;
}

- (id)valueForUndefinedKey:(NSString *)key
{
	DEBUG(@"request for key %@ in mark list %@", key, self);
	if ([key hasPrefix:@"group_by_"])
		return [self groupBy:[key substringFromIndex:9]];
	return [super valueForUndefinedKey:key];
}

- (void)setSelectionIndexes:(NSIndexSet *)indexSet
{
	DEBUG(@"got selection indexes %@", indexSet);
	currentIndex = [indexSet firstIndex];
}

- (NSIndexSet *)selectionIndexes
{
	if (currentIndex >= 0 && currentIndex < [marks count])
		return [NSIndexSet indexSetWithIndex:currentIndex];
	return [NSIndexSet indexSet];
}

- (ViMark *)markAtIndex:(NSInteger)anIndex
{
	if (anIndex >= 0 && anIndex < [marks count]) {
		if (currentIndex != anIndex) {
			[self willChangeValueForKey:@"selectionIndexes"];
			currentIndex = anIndex;
			[self didChangeValueForKey:@"selectionIndexes"];
		}
		return [marks objectAtIndex:currentIndex];
	}
	return nil;
}

- (ViMark *)next
{
	return [self markAtIndex:currentIndex + 1];
}

- (ViMark *)previous
{
	return [self markAtIndex:currentIndex - 1];
}

- (ViMark *)first
{
	return [self markAtIndex:0];
}

- (ViMark *)last
{
	return [self markAtIndex:[marks count] - 1];
}

- (ViMark *)current
{
	return [self markAtIndex:currentIndex];
}

- (NSString *)description
{
	if (identifier)
		return [NSString stringWithFormat:@"<ViMarkList (%@): %lu marks>", identifier, [marks count]];
	else
		return [NSString stringWithFormat:@"<ViMarkList %p: %lu marks>", self, [marks count]];
}

#pragma mark -

- (id)title
{
	return [identifier description];
}

- (BOOL)isLeaf
{
	return NO;
}

- (id)lineNumber
{
	return nil;
}

- (id)columnNumber
{
	return nil;
}

- (NSUInteger)line
{
	return NSNotFound;
}

- (NSUInteger)column
{
	return NSNotFound;
}

@end





@implementation ViMarkStack

@synthesize name, maxLists;

+ (ViMarkStack *)markStackWithName:(NSString *)name
{
	return [[ViMarkStack alloc] initWithName:name];
}

- (ViMarkStack *)initWithName:(NSString *)aName
{
	if ((self = [super init]) != nil) {
		name = aName;
		maxLists = 10;
		[self clear];
		[self makeList];
		DEBUG(@"created mark stack %@", self);
	}
	return self;
}

- (void)clear
{
	[self willChangeValueForKey:@"selectionIndexes"];
	[self willChangeValueForKey:@"list"];
	lists = [NSMutableArray array];
	currentIndex = -1;
	[self didChangeValueForKey:@"list"];
	[self didChangeValueForKey:@"selectionIndexes"];
}

- (ViMarkList *)list
{
	if (currentIndex >= 0) {
		DEBUG(@"returning list at index %li for stack %@", currentIndex, self);
		return [lists objectAtIndex:currentIndex];
	}

	DEBUG(@"no lists added in stack %@", self);
	return nil;
}

- (ViMarkList *)makeList
{
	return [self push:[ViMarkList markList]];
}

- (void)trim
{
	while ([lists count] > maxLists && maxLists > 0) {
		DEBUG(@"trimming list %@ at index 0", [lists objectAtIndex:0]);
		[lists removeObjectAtIndex:0];
	}
	if (currentIndex >= [lists count]) {
		currentIndex = [lists count] - 1;
		DEBUG(@"adjusted currentIndex to %li", currentIndex);
	}
}

- (void)setMaxLists:(NSInteger)num
{
	maxLists = IMAX(1, num);
	if ([lists count] > maxLists) {
		[self willChangeValueForKey:@"selectionIndexes"];
		[self willChangeValueForKey:@"list"];
		[self trim];
		[self didChangeValueForKey:@"list"];
		[self didChangeValueForKey:@"selectionIndexes"];
	}
}

- (ViMarkList *)push:(ViMarkList *)list
{
	[self willChangeValueForKey:@"selectionIndexes"];
	[self willChangeValueForKey:@"list"];

	DEBUG(@"lists before push: %@, currentIndex = %li", lists, currentIndex);

	if (++currentIndex < 0)
		currentIndex = 0;

	if (currentIndex >= [lists count]) {
		DEBUG(@"appending list %@", list);
		[lists addObject:list];
		[self trim];
	} else {
		DEBUG(@"insert list %@ at index %li", list, currentIndex);
		[lists replaceObjectAtIndex:currentIndex withObject:list];
	}

	[self didChangeValueForKey:@"list"];
	[self didChangeValueForKey:@"selectionIndexes"];

	DEBUG(@"lists after push: %@, currentIndex = %li", lists, currentIndex);

	return list;
}

- (void)setSelectionIndexes:(NSIndexSet *)indexSet
{
	DEBUG(@"got selection indexes %@", indexSet);
	[self willChangeValueForKey:@"list"];
	currentIndex = [indexSet firstIndex];
	[self didChangeValueForKey:@"list"];
}

- (NSIndexSet *)selectionIndexes
{
	if (currentIndex >= 0 && currentIndex < [lists count])
		return [NSIndexSet indexSetWithIndex:currentIndex];
	return [NSIndexSet indexSet];
}

- (ViMarkList *)listAtIndex:(NSInteger)anIndex
{
	if (anIndex >= 0 && anIndex < [lists count]) {
		if (currentIndex != anIndex) {
			[self willChangeValueForKey:@"selectionIndexes"];
			[self willChangeValueForKey:@"list"];
			currentIndex = anIndex;
			[self didChangeValueForKey:@"list"];
			[self didChangeValueForKey:@"selectionIndexes"];
		}
		return [lists objectAtIndex:currentIndex];
	}
	return nil;
}

- (ViMarkList *)next
{
	return [self listAtIndex:currentIndex + 1];
}

- (ViMarkList *)previous
{
	return [self listAtIndex:currentIndex - 1];
}

- (ViMarkList *)last
{
	return [self listAtIndex:[lists count] - 1];
}

- (ViMarkList *)current
{
	return [self listAtIndex:currentIndex];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ViMarkStack %p: %@, list %li/%lu>", self, name, currentIndex, [lists count]];
}

@end





@implementation ViMarkManager

@synthesize stacks;

static ViMarkManager *sharedManager = nil;

+ (ViMarkManager *)sharedManager
{
	if (sharedManager == nil)
		sharedManager = [[ViMarkManager alloc] init];
	return sharedManager;
}

- (ViMarkManager *)init
{
	DEBUG(@"self is %@, sharedManager is %@", self, sharedManager);
	if (sharedManager)
		return sharedManager;

	if ((self = [super init]) != nil) {
		stacks = [NSMutableArray array];
		namedStacks = [NSMutableDictionary dictionary];
		marksPerDocument = [NSMapTable mapTableWithWeakToStrongObjects];
		DEBUG(@"created mark manager %@", self);
		[self stackWithName:@"Global Marks"];
		sharedManager = self;
	}
	return self;
}

// This shouldn't be called
- (ViMarkManager *)initWithCoder:(NSCoder *)aCoder
{
	DEBUG(@"self is %@, sharedManager is %@", self, sharedManager);
	if (sharedManager)
		return sharedManager;
	return [self init];
}

- (void)removeStack:(ViMarkStack *)stack
{
	[self willChangeValueForKey:@"stacks"];
	[stacks removeObject:stack];
	[self didChangeValueForKey:@"stacks"];
}

- (void)removeStackWithName:(NSString *)name
{
	ViMarkStack *stack = [namedStacks objectForKey:name];
	if (stack) {
		[namedStacks removeObjectForKey:name];
		[self removeStack:stack];
	}
}

- (ViMarkStack *)addStack:(ViMarkStack *)stack
{
	[self willChangeValueForKey:@"stacks"];
	[stacks addObject:stack];
	[self didChangeValueForKey:@"stacks"];
	return stack;
}

- (ViMarkStack *)makeStack
{
	return [self addStack:[ViMarkStack markStackWithName:@"Untitled"]];
}

- (ViMarkStack *)stackWithName:(NSString *)name
{
	ViMarkStack *stack = [namedStacks objectForKey:name];
	if (stack)
		return stack;

	stack = [ViMarkStack markStackWithName:name];
	[namedStacks setObject:stack forKey:name];
	return [self addStack:stack];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	DEBUG(@"request for key %@ in mark manager %@", key, self);
	return [self stackWithName:key];
}

- (void)registerMark:(ViMark *)mark
{
	if (mark.document == nil)
		return;

	NSHashTable *marks = [marksPerDocument objectForKey:mark.document];
	if (marks == nil) {
		marks = [NSHashTable hashTableWithWeakObjects];
		[marksPerDocument setObject:marks forKey:mark.document];
	}
	[marks addObject:mark];
}

- (void)unregisterMark:(ViMark *)mark
{
	if (mark.document == nil)
		return;

	NSHashTable *marks = [marksPerDocument objectForKey:mark.document];
	if (marks)
		[marks removeObject:mark];
}

- (NSHashTable *)marksForDocument:(ViDocument *)aDocument
{
	return [marksPerDocument objectForKey:aDocument];
}

@end