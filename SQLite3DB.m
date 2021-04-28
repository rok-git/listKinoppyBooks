#import <Foundation/Foundation.h>
#import "SQLite3DB.h"

@implementation SQLite3Stmt : NSObject
-(SQLite3Stmt *)initWithStmt: (sqlite3_stmt *)pStmt
{
    ppStmt = pStmt;
    return self;
}

-(NSArray *) step
{
    int numColumns;
    NSMutableArray *ret = nil;
    switch (sqlite3_step(ppStmt)){
        case SQLITE_ROW:
            numColumns = sqlite3_data_count(ppStmt);
            ret = [[NSMutableArray alloc] init];
            for(int i = 0; i < numColumns; i++){
                switch(sqlite3_column_type(ppStmt, i)){
                    case SQLITE_TEXT:
                        [ret addObject: [NSString stringWithUTF8String: (char *)sqlite3_column_text(ppStmt, i)]];
                        break;
                    case SQLITE_INTEGER:
                        [ret addObject: [NSNumber numberWithInt: sqlite3_column_int(ppStmt, i)]];
                        break;
                    case SQLITE_FLOAT:
                        [ret addObject: [NSNumber numberWithDouble: sqlite3_column_int(ppStmt, i)]];
                        break;
                    case SQLITE_BLOB:
                        [ret addObject: @"SQLITE_BLOB"];
                        break;
                    case SQLITE_NULL:
                        [ret addObject: @"SQLITE_NULL"];
                        break;
                    default:
                        [ret addObject: @"default"];
                        break;
                }
            }
            break;
        case SQLITE_DONE:
            break;
        default:
            break;
    }
    if(ret)
        return [NSArray arrayWithArray: ret];
    else
        return nil;
}

-(void) done
{
    sqlite3_finalize(ppStmt);           // maybe checking return value needed
}
@end

@implementation SQLite3DB : NSObject
-(SQLite3DB *) init
{
    connection = NULL;
    return self;
}

-(BOOL) connectDB: (NSString *)dbpath
{
    if(sqlite3_open([[dbpath stringByExpandingTildeInPath] UTF8String], &connection) != SQLITE_OK)
        return NO;
    else
        return YES;
}

-(BOOL) disconnectDB
{
    if(sqlite3_close(connection) != SQLITE_OK)
        return NO;
    else
        return YES;
}

-(SQLite3Stmt *) prepareStmt: (NSString *)sqlStmt
{
    sqlite3_stmt *pStmt = NULL;

    if( sqlite3_prepare_v2(connection, [sqlStmt UTF8String], MAX_SQL_LEN, &pStmt, NULL) != SQLITE_OK ){
        return nil;
    }else{
        SQLite3Stmt *ret = [[SQLite3Stmt alloc] initWithStmt: pStmt];
        return ret;
    }

}
@end

