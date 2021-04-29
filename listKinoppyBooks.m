#import <Foundation/Foundation.h>
#import "SQLite3DB.h"

#define dbFile @"~/Library/Containers/jp.co.kinokuniya.kinoppy/Data/Library/Application Support/jp.co.kinokuniya.kinoppy/.Contents/0_1046260"
#define SQL1 @"select \
        author_name, \
        author_kana, \
        title, \
        title_kana, \
        publisher_name, \
        purchase_date, \
        isbn \
    from    Book  \
        left join ( \
            select \
                name as author_name, \
                name_kana as author_kana,\
                book_id \
            from Author, BookAuthor using(author_id)) \
            using (book_id) \
        left join ( \
            select \
                name as publisher_name, \
                book_id \
            from Publisher, BookPublisher using(publisher_id)) \
            using (book_id) \
    order by purchase_date;"
#define DATE_FORMAT @"yyyy-MM-dd HH:mm:ss"
#define DEF_TZ @"JST"
#define DATE_EPOCH @"1970-01-01"
#define NULLSTR @""


int
main()
{
    @autoreleasepool{
        NSError *err = nil;
        NSString *str = DATE_EPOCH;  // Epoch of Kinoppy's buydate ?
        NSDataDetector *det = [NSDataDetector dataDetectorWithTypes: NSTextCheckingTypeDate error: &err];
        NSTextCheckingResult *match = [det firstMatchInString: str options: 0 range: NSMakeRange(0, [str length])];
        NSDate *refDate = [match date];
        NSDate *date;

        NSFileHandle *fout = [NSFileHandle fileHandleWithStandardOutput];
        SQLite3DB *db = [[SQLite3DB alloc] init];
        if([db connectDB: dbFile]){
            SQLite3Stmt *stmt = [db prepareStmt: SQL1];
            if(!stmt){
                NSLog(@"preparing statment failed");
                exit(1);
            }
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = DATE_FORMAT;
            dateFormatter.timeZone = [NSTimeZone timeZoneWithName: DEF_TZ];
            NSArray *data;
            NSString *outStr;
            int count = 0;
            NSMutableDictionary *bookData = [NSMutableDictionary dictionary]; // key: isbn, value: book info
            NSString *key = nil;
            while((data = [stmt step])){
                key = data[6];          // use isbn as a key in default
                if(key.length == 0){
                    key = data[2];      // no isbn found then use title as key
                }
                if(bookData[key]){
                    // Already an entry exists.  
                    // This may occur when more than one author_name or more than one author_kana exist.
                    // Other info must be the same.
                    // But, perhaps data[4] (publisher name) can be multiple value……
                    // if it occurs modify code here.
                    for(int i = 0; i < 2; i++){
                        // only data[0] (author name), data[1] (author name in kana) can have  mutliple values;
                        if(data[i]){
                            [bookData[key][i] addObject: data[i]];
                        }
                    }
                }else{
                    // No entry exists.  Create new one.
                    bookData[key] = @[
                        [@[data[0]] mutableCopy],
                        [@[data[1]] mutableCopy],
                        data[2],
                        data[3], 
                        data[4], 
                        [NSDate dateWithTimeInterval: [data[5] doubleValue] sinceDate: refDate],
                        data[6]
                    ];
                }
            }
            [bookData enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSArray *values, BOOL *stop){
                NSString *authors = [[[values[0] componentsJoinedByString: @", "] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""] stringByReplacingOccurrencesOfString: @"SQLITE_NULL" withString: NULLSTR];
                NSString *authors_kana = [[[values[1] componentsJoinedByString: @", "] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""] stringByReplacingOccurrencesOfString: @"SQLITE_NULL" withString: NULLSTR];
                NSString *title = [values[2] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""];
                NSString *title_kana =[values[3] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""];
                NSString *publisher = [[values[4] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""] stringByReplacingOccurrencesOfString: @"SQLITE_NULL" withString: NULLSTR];
                NSString *purchase_date = [[dateFormatter stringFromDate: values[5]] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""];
                NSString *outStr = [NSString
                    stringWithFormat: @"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n",
                    authors, authors_kana, title, title_kana, publisher, purchase_date];
                [fout writeData: [outStr dataUsingEncoding: NSUTF8StringEncoding]];;
            }];
            [stmt done];
            [db disconnectDB];
        }else{
            NSLog(@"database connection faild: %@", dbFile);
            exit(1);
        }
    }
    return 0;
}
