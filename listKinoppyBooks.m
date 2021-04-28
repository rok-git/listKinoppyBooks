#import <Foundation/Foundation.h>
#import "SQLite3DB.h"

#define dbFile @"~/Library/Containers/jp.co.kinokuniya.kinoppy/Data/Library/Application Support/jp.co.kinokuniya.kinoppy/.Contents/0_1046260"
#define SQL1 @"select \
        author_display, \
        author_kana, \
        title, \
        title_kana, \
        publisher_name, \
        purchase_date, \
        isbn \
    from    Book  \
        join ( \
            select \
                name_kana as author_kana,\
                book_id \
            from Author, BookAuthor using(author_id)) \
            using (book_id) \
        join ( \
            select \
                name as publisher_name, \
                book_id \
            from Publisher, BookPublisher using(publisher_id)) \
            using (book_id) \
    order by purchase_date;"
#define DATE_FORMAT @"yyyy-MM-dd HH:mm:ss"
#define DEF_TZ @"JST"
#define DATE_EPOCH @"1970-01-01"


int
main()
{
    @autoreleasepool{
        NSError *err = nil;
        NSString *str = DATE_EPOCH;  // Epoch of BOOKWALKER's buydate ?
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
            while((data = [stmt step])){
                date = [NSDate dateWithTimeInterval: [data[5] doubleValue] sinceDate: refDate];
                outStr = [NSString
                    stringWithFormat: @"\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\"\n",
                    [data[0] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""],
                    [data[1] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""],
                    [data[2] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""],
                    [data[3] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""],
                    [data[4] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""],
                    [[dateFormatter stringFromDate: date] stringByReplacingOccurrencesOfString: @"\"" withString: @"\"\""]];
                [fout writeData: [outStr dataUsingEncoding: NSUTF8StringEncoding]];;
            }
            [stmt done];
            [db disconnectDB];
        }else{
            NSLog(@"database connection faild: %@", dbFile);
            exit(1);
        }
    }
    return 0;
}
