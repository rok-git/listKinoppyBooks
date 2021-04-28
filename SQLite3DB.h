#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define MAX_SQL_LEN 1024

@interface SQLite3Stmt : NSObject {
    sqlite3_stmt * ppStmt;
    char * pzTail;
}
-(SQLite3Stmt *) initWithStmt: (sqlite3_stmt *)stmt;
-(NSArray *) step;      // return a row
-(void) done;
@end



@interface SQLite3DB : NSObject {
    sqlite3 *connection;
}

-(SQLite3DB *) init;

-(BOOL) connectDB: (NSString *)dbpath;
-(BOOL) disconnectDB;

-(SQLite3Stmt *) prepareStmt: (NSString *)sqlStmt; // return nil if error


@end
