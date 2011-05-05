@protocol ViDeferred;

@protocol ViDeferredDelegate <NSObject>
@optional
- (void)deferred:(id<ViDeferred>)deferred status:(NSString *)statusMessage;
@end

@protocol ViDeferred <NSObject>
@required
- (void)cancel;
@property (readwrite, assign) id<ViDeferredDelegate> delegate;

@optional
- (CGFloat)progress;
@end

@protocol ViURLHandler <NSObject>
@required
- (BOOL)respondsToURL:(NSURL *)aURL;
- (NSURL *)normalizeURL:(NSURL *)aURL;

@optional
- (id<ViDeferred>)attributesOfItemAtURL:(NSURL *)aURL
			   onCompletion:(void (^)(NSURL *, NSDictionary *, NSError *))aBlock;
- (id<ViDeferred>)fileExistsAtURL:(NSURL *)aURL
		     onCompletion:(void (^)(NSURL *, BOOL, NSError *))aBlock;
- (id<ViDeferred>)dataWithContentsOfURL:(NSURL *)aURL
				 onData:(void (^)(NSData *))dataCallback
			   onCompletion:(void (^)(NSURL *, NSDictionary *, NSError *))completionCallback;

- (id<ViDeferred>)contentsOfDirectoryAtURL:(NSURL *)aURL onCompletion:(void (^)(NSArray *, NSError *))aBlock;
- (id<ViDeferred>)createDirectoryAtURL:(NSURL *)aURL onCompletion:(void (^)(NSError *))aBlock;
- (id<ViDeferred>)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL onCompletion:(void (^)(NSError *))aBlock;
- (id<ViDeferred>)removeItemsAtURLs:(NSArray *)urls onCompletion:(void (^)(NSError *))aBlock;
- (id<ViDeferred>)writeDataSafely:(NSData *)data
			    toURL:(NSURL *)aURL
		     onCompletion:(void (^)(NSURL *, NSError *))aBlock;
- (id<ViDeferred>)removeItemAtURL:(NSURL *)aURL onCompletion:(void (^)(NSError *))aBlock;
@end

@interface ViURLManager : NSObject <ViURLHandler>
{
	NSMutableArray *handlers;
	NSMutableDictionary *directoryCache;
}
+ (ViURLManager *)defaultManager;
- (void)registerHandler:(id<ViURLHandler>)handler;
- (void)flushDirectoryCache;
@end