//
//  Manga+Parse.m
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "Manga+Parse.h"
#import "MangaComment.h"
#import <objc/runtime.h>

const void *parseObjectKey = &parseObjectKey;
const void *parseReadingCountKey = &parseReadingCountKey;
const void *parseCommentsCountKey = &parseCommentsCountKey;

@implementation Manga (Parse)

- (void)queryReadingCountWithCompletionBlock:(void (^)(int))completionBlock {
    
}

- (void)createMangaIfNeededWithCompletionBlock:(void (^)(PFObject *))completionBlock {
    NSString *className = NSStringFromClass(self.class);
    NSString *key = NSStringFromSelector(@selector(url));
    NSString *value = self.url.absoluteString;
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:key equalTo:value];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count > 0) {
                [self setParseObject:[objects firstObject]];
                if (completionBlock) {
                    completionBlock([objects firstObject]);
                }
            } else {
                PFObject *object = [PFObject objectWithClassName:className];
                object[key] = value;
                object[readingCountKey] = @(0);
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"succeeded");
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            if (!error) {
                                if (objects.count > 0) {
                                    [self setParseObject:[objects firstObject]];
                                    if (completionBlock) {
                                        completionBlock([objects firstObject]);
                                    }
                                } else {
                                    
                                }
                            }
                        }];
                        
                    }
                }];
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)incrementReadingCountWithCompletionBlock:(void (^)(int))completionBlock {
    __weak typeof (self) selfie = self;
    [self createMangaIfNeededWithCompletionBlock:^(PFObject *mangaPFObject) {
        [mangaPFObject incrementKey:readingCountKey];
        [mangaPFObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [selfie refreshPFObjectWithCompletionBlock:^(PFObject *mangaPFObject) {
                [selfie setParseObject:mangaPFObject];
                [selfie setReadingCount:[mangaPFObject[readingCountKey] intValue]];
                if (completionBlock) {
                    completionBlock([mangaPFObject[readingCountKey] intValue]);
                }
            }];
        }];
    }];
}

- (void)refreshPFObjectWithCompletionBlock:(void (^)(PFObject *))completionBlock {
    PFObject *object = [self parseObject];
    if (object) {
        [object fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (completionBlock) {
                completionBlock(object);
            }
        }];
    }
}

- (void)fetchCommentsWithCompletionBlock:(void (^)(NSArray *, NSError *))completionBlock {
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([MangaComment class])];
    [query whereKey:NSStringFromSelector(@selector(mangaURL)) equalTo:self.url.absoluteString];
    [query orderByDescending:NSStringFromSelector(@selector(createdAt))];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (completionBlock) {
                NSMutableArray *comments = [NSMutableArray arrayWithCapacity:objects.count];
                for (PFObject *obj in objects) {
                    MangaComment *mc = [[MangaComment alloc] init];
                    [mc setValue:obj[@"username"] forKey:NSStringFromSelector(@selector(username))];
                    [mc setValue:obj[@"string"] forKey:NSStringFromSelector(@selector(string))];
                    [mc setValue:obj[@"createdAt"] forKey:NSStringFromSelector(@selector(createdAt))];
                    
                    [comments addObject:mc];
                }
                completionBlock(comments, nil);
            }
        } else {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }
    }];
}

- (void)addComment:(NSString *)comment completionBlock:(void (^)(NSError *))completionBlock {
    PFObject *object = [PFObject objectWithClassName:NSStringFromClass([MangaComment class])];
    object[NSStringFromSelector(@selector(string))] = comment;
    PFUser *user = [PFUser currentUser];
    object[NSStringFromSelector(@selector(username))] = user.username;
    object[NSStringFromSelector(@selector(mangaURL))] = self.url.absoluteString;
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if (completionBlock) {
                completionBlock(nil);
            }
        } else {
            if (completionBlock) {
                completionBlock(error);
            }
        }
    }];
}

- (void)countCommentsWithCompletionBlock:(void (^)(int))completionBlock {
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([MangaComment class])];
    [query whereKey:NSStringFromSelector(@selector(mangaURL)) equalTo:self.url.absoluteString];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            // The count request succeeded. Log the count
            [self setCommentsCount:count];
            if (completionBlock) {
                completionBlock(count);
            }
        } else {
            // The request failed
        }
    }];
}

- (void)setParseObject:(PFObject *)parseObject {
    [self setReadingCount:[parseObject[readingCountKey] intValue]];
    objc_setAssociatedObject(self, parseObjectKey, parseObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PFObject *)parseObject {
    return objc_getAssociatedObject(self, parseObjectKey);
}

- (void)setReadingCount:(int)readingCount {
    objc_setAssociatedObject(self, parseReadingCountKey, @(readingCount), OBJC_ASSOCIATION_ASSIGN);
}

- (int)readingCount {
    return [objc_getAssociatedObject(self, parseReadingCountKey) intValue];
}

- (void)setCommentsCount:(int)commentsCount {
    objc_setAssociatedObject(self, parseCommentsCountKey, @(commentsCount), OBJC_ASSOCIATION_ASSIGN);
}

- (int)commentsCount {
    return [objc_getAssociatedObject(self, parseCommentsCountKey) intValue];
}

@end
