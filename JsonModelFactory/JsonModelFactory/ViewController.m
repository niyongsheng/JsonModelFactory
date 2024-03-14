//
//  ViewController.m
//  JsonModelFactory
//
//  Created by niyongsheng on 2024/3/14.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <GitHubUpdates/GitHubUpdates.h>


#define kNYS_DEFAULT_CLASS_NAME                         @("NYSModel")
#define kNYS_CLASS                                      @("\n@interface %@ :NSObject\n%@\n@end\n")
#define kNYS_BASE_CLASS                                 @("\n@interface %@ :NYSBaseObject\n%@\n@end\n")
#define kNYS_CodingCLASS                                @("\n@interface %@ :NSObject <NSCoding>\n%@\n@end\n")
#define kNYS_CopyingCLASS                               @("\n@interface %@ :NSObject <NSCopying>\n%@\n@end\n")
#define kNYS_CodingAndCopyingCLASS                      @("\n@interface %@ :NSObject <NSCoding,NSCopying>\n%@\n@end\n")

#define kNYS_PROPERTY(s)                                ((s) == 'c' ? @("@property (nonatomic , copy) %@              * %@;\n") : @("@property (nonatomic , strong) %@              * %@;\n"))
#define kNYS_ASSIGN_PROPERTY                            @("@property (nonatomic , assign) %@              %@;\n")
#define kNYS_CLASS_M                                    @("@implementation %@\n\n@end\n")
#define kNYS_CodingCLASS_M                              @("@implementation %@\n- (id)initWithCoder:(NSCoder *)decoder {\n       if (self = [super init]) { \n              [self nys_Decode:decoder]; \n       }\n       return self;\n  \n} \n- (void)encodeWithCoder:(NSCoder *)encoder {\n       [self nys_Encode:encoder]; \n} \n\n\n@end\n\n")

#define kNYS_CopyingCLASS_M                             @("@implementation %@ \n- (id)copyWithZone:(NSZone *)zone { \n       return [self nys_Copy]; \n} \n\n\n@end\n\n")
#define kNYS_CodingAndCopyingCLASS_M                    @("@implementation %@ \n- (id)initWithCoder:(NSCoder *)decoder {\n       if (self = [super init]) { \n              [self nys_Decode:decoder]; \n       }\n        return self;\n } \n\n- (void)encodeWithCoder:(NSCoder *)encoder {\n       [self nys_Encode:encoder]; \n} \n\n - (id)copyWithZone:(NSZone *)zone { \n       return [self nys_Copy]; \n} \n \n@end\n\n")

#define kNYS_CLASS_Prefix_M                             @("@implementation %@\n+ (NSString *)prefix {\n    return @\"%@\";\n}\n\n@end\n\n")

#define kNYS_Prefix_H_Func                              @("\n+ (NSString *)prefix;\n")

#define kSNYS_Prefix_Func                               @("class func prefix() -> String {\n    return \"%@\"\n}\n")

#define kSNYS_CLASS                                     @("\nclass %@ :NSObject {\n%@\n}\n")
#define kYYModel_Swift_CLASS                            @("\nclass %@ :NYSBaseObject {\n%@\n}\n")
#define kSexyJson_Class                                 @("\nclass %@: SexyJson {\n%@\n}\n")
#define kSexyJson_Struct                                @("\nstruct %@: SexyJson {\n%@\n}\n")
#define kExCodable_Struct                               @("\nstruct %@: Equatable, ExAutoCodable {\n%@\n}\n")

#define kSexyJson_FuncMap                               (@"\n       public func sexyMap(_ map: [String : Any]) {\n       %@       \n       }\n")
#define kSexyJson_Struct_FuncMap                        (@"\n       public mutating func sexyMap(_ map: [String : Any]) {\n       %@       \n       }\n")
#define kSexyJson_Map                                   (@"\n              %@        <<<        map[\"%@\"]")

#define kSexyJson_CodingCLASS                           @("\nclass %@ :NSObject, SexyJson, NSCoding {\n \n       required init(coder decoder: NSCoder) {\n              super.init()\n              self.sexy_decode(decoder)\n       }\n\n       func encode(with aCoder: NSCoder) {\n              self.sexy_encode(aCoder)\n       }\n\n       required override init() {}  \n\n%@\n}\n")

#define kSexyJson_CopyingCLASS                          @("\nclass %@ :NSObject, SexyJson, NSCopying {\n \n       func copy(with zone: NSZone? = nil) -> Any {\n              return self.sexy_copy()\n       }\n\n       required override init() {}  \n\n %@\n}\n")

#define kSexyJson_CodingAndCopyingCLASS                 @("\nclass %@ :NSObject, SexyJson, NSCoding, NSCopying {\n\n       required init(coder decoder: NSCoder) {\n              super.init()\n              self.sexy_decode(decoder)\n       }\n\n       func encode(with aCoder: NSCoder) {\n              self.sexy_encode(aCoder)\n       } \n\n       func copy(with zone: NSZone? = nil) -> Any {\n              return self.sexy_copy()\n       }\n\n       required override init() {} \n\n%@\n}\n")

#define kSNYS_CodingCLASS                               @("\nclass %@ :NSObject, NSCoding {\n \n       required init(coder aDecoder: NSCoder) {\n              super.init()\n              self.nys_Decode(aDecoder)\n       }\n\n       func encode(with aCoder: NSCoder) {\n              self.nys_Encode(aCoder)\n       }  \n\n%@\n}\n")

#define kSNYS_CopyingCLASS                              @("\nclass %@ :NSObject, NSCopying {\n \n       func copy(with zone: NSZone? = nil) -> Any {\n              return self.nys_Copy()\n       }  \n\n %@\n}\n")

#define kSNYS_CodingAndCopyingCLASS                     @("\nclass %@ :NSObject, NSCoding, NSCopying {\n\n       required init(coder aDecoder: NSCoder) {\n              super.init()\n              self.nys_Decode(aDecoder)\n       }\n\n       func encode(with aCoder: NSCoder) {\n              self.nys_Encode(aCoder)\n       } \n\n       func copy(zone: NSZone? = nil) -> Any {\n              return self.nys_Copy()\n       } \n\n%@\n}\n")

// Swift
#define kSNYS_PROPERTY                                  @("       @objc var %@: %@?\n")
#define kSNYS_ASSGIN_PROPERTY                           @("       @objc var %@: %@\n")

// ExCodable
#define kSENYS_PROPERTY                                 @("       @ExCodable\n       private(set) var %@: %@?\n")
#define kSENYS_ASSGIN_PROPERTY                          @("       @ExCodable\n       private(set) var %@: %@\n")

// Tips
#define kInputJsonPlaceholdText                         @("please input json or xml string")
#define kHeaderPlaceholdText                            @(".h file")
#define kSourcePlaceholdText                            @(".m file")


typedef enum : NSUInteger {
    Objc = 0,
    ObjcYYModel,
    Swift,
    SwiftYYModel, // TODO: modelContainerPropertyGenericClass
    SwiftExCodable,
    SexyJson_struct,
    SexyJson_class
} ModelType;

@interface ViewController (){
    NSMutableString       *   _classString;        //存类头文件内容
    NSMutableString       *   _classMString;       //存类源文件内容
    NSString              *   _classPrefixName;    //类前缀
    BOOL                      _didMake;
    BOOL                      _firstLower;         //首字母小写
    BOOL                      _classBaseNYS;       //NYSBaseObject基类
}
@property (nonatomic, strong) GitHubUpdater *updater;
@property (weak) IBOutlet NSLayoutConstraint *classMHeightConstraint;

@property (nonatomic , strong)IBOutlet  NSTextField  * classNameField;
@property (nonatomic , strong)IBOutlet  NSTextView  * jsonField;
@property (nonatomic , strong)IBOutlet  NSTextView  * classField;
@property (nonatomic , strong)IBOutlet  NSTextView  * classMField;
@property (nonatomic , strong)IBOutlet  NSComboBox       * comboBox;
@property (nonatomic , strong)IBOutlet  NSButton       * codingCheckBox;
@property (nonatomic , strong)IBOutlet  NSButton       * copyingCheckBox;
@property (nonatomic , strong)IBOutlet  NSButton       * classBaseNYSBox;
@property (nonatomic , strong)IBOutlet  NSButton       * githubBtn;

@property (nonatomic , strong) NSArray * comboxTitles;
@property (nonatomic , assign) BOOL isSwift;
@property (nonatomic , assign) ModelType modelType;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _classString = [NSMutableString new];
    _classMString = [NSMutableString new];
    _classField.editable = NO;
    _classMField.editable = NO;
    _firstLower = YES;
    // Do any additional setup after loading the view.
    [self setTextViewStyle];
    [self setClassSourceContent:kSourcePlaceholdText];
    [self setClassHeaderContent:kHeaderPlaceholdText];
    NSRect frmae = self.view.frame;
    frmae.size.height = 800;
    self.view.frame = frmae;
    
    //    _comboxTitles = @[@"Objective-C", @"ObjcYYModel", @"Swift", @"SwiftExCodable", @"SexyJson(struct)", @"SexyJson(class)"];
    _comboxTitles = @[@"Objective-C", @"ObjcYYModel", @"Swift", @"SwiftExCodable"];
    [_comboBox addItemsWithObjectValues:_comboxTitles];
    [_comboBox selectItemWithObjectValue:@"Objective-C"];
    
    [self.updater checkForUpdatesInBackground];
}

- (GitHubUpdater *)updater {
    if (!_updater) {
        _updater = [GitHubUpdater new];
        _updater.user = @"niyongsheng";
        _updater.repository = @"JsonModelFactory";
    }
    return _updater;
}

- (void)setJsonContent:(NSString *)content {
    if (content != nil) {
        NSMutableAttributedString * attrContent = [[NSMutableAttributedString alloc] initWithString:content];
        [_jsonField.textStorage setAttributedString:attrContent];
        [_jsonField.textStorage setFont:[NSFont systemFontOfSize:14]];
        [_jsonField.textStorage setForegroundColor:[NSColor colorWithRed:0.00 green:0.66 blue:0.98 alpha:1.00]]; // json text color
    }
}

- (NSString *)copyingRight {
    NSMutableString * value = [NSMutableString string];
    NSDate * date = [NSDate date];
    NSDateFormatter * dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString * dateStr = [dateFormatter stringFromDate:date];
    [value appendString:@"/**\n  * Created by JsonModelFactory"];
    [value appendString:@" \n  * Copyright © "];
    [value appendString:[dateStr componentsSeparatedByString:@"-"].firstObject];
    [value appendString:@"年 NYS.\n  */\n\n"];
    return value;
}

- (void)setClassHeaderContent:(NSString *)content {
    if (content != nil) {
        NSMutableAttributedString * attrContent = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",[content isEqualToString:kHeaderPlaceholdText] ? @"" : [self copyingRight],content]];
        [_classField.textStorage setAttributedString:attrContent];
        [_classField.textStorage setFont:[NSFont systemFontOfSize:14]];
        [_classField.textStorage setForegroundColor:[NSColor colorWithRed:0.89 green:0.20 blue:0.60 alpha:1.00]]; // .h text color
        
    }
}

- (void)setClassSourceContent:(NSString *)content {
    if (content != nil) {
        NSMutableAttributedString * attrContent = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",[content isEqualToString:kSourcePlaceholdText] ? @"" : [self copyingRight],content]];
        [_classMField.textStorage setAttributedString:attrContent];
        [_classMField.textStorage setFont:[NSFont systemFontOfSize:14]];
        [_classMField.textStorage setForegroundColor:[NSColor colorWithRed:0.00 green:0.97 blue:0.56 alpha:1.00]]; // .m text color
    }
}

- (void)setTextViewStyle {
    _jsonField.font = [NSFont systemFontOfSize:14];
    _jsonField.textColor = NSColor.redColor; // json text default color
    _jsonField.backgroundColor = [NSColor colorWithRed:0.00 green:0.17 blue:0.21 alpha:1.00];
    _classMField.backgroundColor = _jsonField.backgroundColor;
    _classField.backgroundColor = _jsonField.backgroundColor;
}

- (IBAction)clickGithubBtn:(NSButton *)sender {
//    [self.updater checkingForUpdates];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/niyongsheng/JsonModelFactory"]];
}

- (IBAction)clickBaseClass:(NSButton *)sender {
    _classBaseNYS = sender.state == 1;
    NSString  * json = _jsonField.textStorage.string;
    if (json && json.length > 0) {
        [self clickMakeButton:nil];
    }
    
}

- (IBAction)clickFirstLower:(NSButton *)sender {
    _firstLower = sender.state == 1;
    NSString  * json = _jsonField.textStorage.string;
    if (json && json.length > 0) {
        [self clickMakeButton:nil];
    }
    
}

- (IBAction)clickRadioButtone:(NSButton *)sender{
    NSString  * json = _jsonField.textStorage.string;
    if (json && json.length > 0) {
        [self clickMakeButton:nil];
    }
    
}
- (IBAction)clickChangeComboBox:(NSComboBox *)sender {
    _isSwift = sender.indexOfSelectedItem > 1;
    
    NSString *selectedTitle = _comboxTitles[sender.indexOfSelectedItem];
    if ([selectedTitle isEqualTo:@"Objective-C"]) {
        _modelType = Objc;
    } else if ([selectedTitle isEqualTo:@"ObjcYYModel"]) {
        _modelType = ObjcYYModel;
    } else if ([selectedTitle isEqualTo:@"Swift"]) {
        _modelType = Swift;
    } else if ([selectedTitle isEqualTo:@"SwiftExCodable"]) {
        _modelType = SwiftExCodable;
    } else if ([selectedTitle isEqualTo:@"SexyJson(struct)"]) {
        _modelType = SexyJson_struct;
    } else if ([selectedTitle isEqualTo:@"SexyJson(class)"]) {
        _modelType = SexyJson_class;
    }
    _classMHeightConstraint.constant = (self.isSwift ? 0 : 180);
    NSString  * json = _jsonField.textStorage.string;
    if (json && json.length > 0) {
        [self clickMakeButton:nil];
    }
}

- (IBAction)clickMakeButton:(NSButton*)sender{
    _didMake = YES;
    [_classString deleteCharactersInRange:NSMakeRange(0, _classString.length)];
    [_classMString deleteCharactersInRange:NSMakeRange(0, _classMString.length)];
    NSString  * className = _classNameField.stringValue;
    NSString  * json = _jsonField.textStorage.string;
    _classPrefixName = @"";
    if(className == nil){
        className = kNYS_DEFAULT_CLASS_NAME;
    }
    if(className.length == 0){
        className = kNYS_DEFAULT_CLASS_NAME;
    }
    if(json && json.length){
        NSDictionary  * dict = nil;
        //json
        NSData  * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        if (jsonObject) {
            NSData * formatJsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
            [self setJsonContent:[[NSString alloc] initWithData:formatJsonData encoding:NSUTF8StringEncoding]];
        }
        dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:NULL];
        if (dict == nil) {
            NSError *error;
            NSPropertyListFormat plistFormat;
            dict = [NSPropertyListSerialization propertyListWithData:jsonData options:NSPropertyListMutableContainers format:&plistFormat error:&error];
        }
        if (dict == nil || ![NSJSONSerialization isValidJSONObject:dict]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
            NSAlert * alert = [NSAlert alertWithMessageText:@"JsonModelFactory" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"未知数据格式无法解析(请提供json字符串或者dictionary字符串)"];
            [alert runModal];
#pragma clang diagnostic pop
            return;
        }
        NSString * classContent = [self handleDataEngine:dict key:@""];
        if(!self.isSwift){
            if (_classPrefixName.length > 0) {
                [_classMString appendFormat:kNYS_CLASS_Prefix_M,className,_classPrefixName];
            }else {
                if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                    [_classMString appendFormat:kNYS_CodingAndCopyingCLASS_M,className];
                }else if (_codingCheckBox.state != 0) {
                    [_classMString appendFormat:kNYS_CodingCLASS_M,className];
                }else if (_copyingCheckBox.state != 0) {
                    [_classMString appendFormat:kNYS_CopyingCLASS_M,className];
                }else {
                    [_classMString appendFormat:kNYS_CLASS_M,className];
                }
            }
            if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                [_classString appendFormat:kNYS_CodingAndCopyingCLASS,className,classContent];
            }else if (_codingCheckBox.state != 0) {
                [_classString appendFormat:kNYS_CodingCLASS,className,classContent];
            }else if (_copyingCheckBox.state != 0) {
                [_classString appendFormat:kNYS_CopyingCLASS,className,classContent];
            }else if (_classBaseNYSBox.state != 0) {
                [_classString appendFormat:kNYS_BASE_CLASS,className,classContent];
            }else {
                [_classString appendFormat:kNYS_CLASS,className,classContent];
            }
        }else{
            switch (_modelType) {
                case SexyJson_class: {
                    if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                        [_classString appendFormat:kSexyJson_CodingAndCopyingCLASS,className,classContent];
                    }else if (_codingCheckBox.state != 0) {
                        [_classString appendFormat:kSexyJson_CodingCLASS,className,classContent];
                    }else if (_copyingCheckBox.state != 0) {
                        [_classString appendFormat:kSexyJson_CopyingCLASS,className,classContent];
                    }else {
                        [_classString appendFormat:kSexyJson_Class,className,classContent];
                    }
                }
                    break;
                case SexyJson_struct:
                    [_classString appendFormat:kSexyJson_Struct,className,classContent];
                    break;
                case SwiftExCodable:
                    [_classString appendFormat:kExCodable_Struct,className,classContent];
                    break;
                default:
                    if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                        [_classString appendFormat:kSNYS_CodingAndCopyingCLASS,className,classContent];
                    }else if (_codingCheckBox.state != 0) {
                        
                        [_classString appendFormat:kSNYS_CodingCLASS,className,classContent];
                    }else if (_copyingCheckBox.state != 0) {
                        [_classString appendFormat:kSNYS_CopyingCLASS,className,classContent];
                    }else {
                        [_classString appendFormat:_classBaseNYS ? kYYModel_Swift_CLASS : kSNYS_CLASS,className,classContent];
                    }
                    break;
            }
        }
        [self setClassHeaderContent:_classString];
        [self setClassSourceContent:_classMString];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        NSAlert * alert = [NSAlert alertWithMessageText:@"JsonModelFactory" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", kInputJsonPlaceholdText];
        [alert runModal];
#pragma clang diagnostic pop
    }
}

- (NSString *)handleAfterClassName:(NSString *)className {
    if (className != nil && className.length > 0) {
        NSString * first = [className substringToIndex:1];
        NSString * other = [className substringFromIndex:1];
        return [NSString stringWithFormat:@"%@%@%@",_classPrefixName,[first uppercaseString],other];
    }
    return className;
}

- (NSString *)handlePropertyName:(NSString *)propertyName {
    if (_firstLower) {
        if (propertyName != nil && propertyName.length > 0) {
            NSString * first = [propertyName substringToIndex:1];
            NSString * other = [propertyName substringFromIndex:1];
            return [NSString stringWithFormat:@"%@%@",[first lowercaseString],other];
        }
    }
    return propertyName;
}

#pragma mark -解析处理引擎-

- (NSString*)handleDataEngine:(id)object key:(NSString*)key{
    if(object){
        NSMutableString  * property = [NSMutableString new];
        NSMutableString  * propertyMap = [NSMutableString new];
        if([object isKindOfClass:[NSDictionary class]]){
            NSDictionary  * dict = object;
            if (_classPrefixName.length > 0) {
                if (!self.isSwift) {
                    [property appendFormat:kNYS_Prefix_H_Func,_classPrefixName];
                }else {
                    [property appendFormat:kSNYS_Prefix_Func,_classPrefixName];
                }
            }
            [dict enumerateKeysAndObjectsUsingBlock:^(NSString * key, id  _Nonnull subObject, BOOL * _Nonnull stop) {
                NSString * className = [self handleAfterClassName:key];
                NSString * propertyName = [self handlePropertyName:key];
                if([subObject isKindOfClass:[NSDictionary class]]){
                    NSString * classContent = [self handleDataEngine:subObject key:key];
                    if(!self.isSwift) {
                        [property appendFormat:kNYS_PROPERTY('s'),className,propertyName];
                        if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                            [_classString appendFormat:kNYS_CodingAndCopyingCLASS,className,classContent];
                        }else if (_codingCheckBox.state != 0) {
                            [_classString appendFormat:kNYS_CodingCLASS,className,classContent];
                        }else if (_copyingCheckBox.state != 0) {
                            [_classString appendFormat:kNYS_CopyingCLASS,className,classContent];
                        }else if (_classBaseNYSBox.state != 0) {
                            [_classString appendFormat:kNYS_BASE_CLASS,className,classContent];
                        }else {
                            [_classString appendFormat:kNYS_CLASS,className,classContent];
                        }
                        if (_classPrefixName.length > 0) {
                            [_classMString appendFormat:kNYS_CLASS_Prefix_M,className,_classPrefixName];
                        }else {
                            if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                [_classMString appendFormat:kNYS_CodingAndCopyingCLASS_M,className];
                            }else if (_codingCheckBox.state != 0) {
                                [_classMString appendFormat:kNYS_CodingCLASS_M,className];
                            }else if (_copyingCheckBox.state != 0) {
                                [_classMString appendFormat:kNYS_CopyingCLASS_M,className];
                            }else {
                                [_classMString appendFormat:kNYS_CLASS_M,className];
                            }
                        }
                    }else{
                        
                        [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,className];
                        switch (_modelType) {
                            case SexyJson_class:
                                if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                    [_classString appendFormat:kSexyJson_CodingAndCopyingCLASS,className,classContent];
                                }else if (_codingCheckBox.state != 0) {
                                    
                                    [_classString appendFormat:kSexyJson_CodingCLASS,className,classContent];
                                }else if (_copyingCheckBox.state != 0) {
                                    [_classString appendFormat:kSexyJson_CopyingCLASS,className,classContent];
                                }else {
                                    [_classString appendFormat:kSexyJson_Class,className,classContent];
                                }
                                [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                                break;
                            case SexyJson_struct:
                                [_classString appendFormat:kSexyJson_Struct,className,classContent];
                                [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                                break;
                            case SwiftExCodable:
                                [_classString appendFormat:kExCodable_Struct,className,classContent];
                                break;
                            default:
                                if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                    [_classString appendFormat:kSNYS_CodingAndCopyingCLASS,className,classContent];
                                }else if (_codingCheckBox.state != 0) {
                                    
                                    [_classString appendFormat:kSNYS_CodingCLASS,className,classContent];
                                }else if (_copyingCheckBox.state != 0) {
                                    [_classString appendFormat:kSNYS_CopyingCLASS,className,classContent];
                                }else {
                                    [_classString appendFormat:_classBaseNYS ? kYYModel_Swift_CLASS : kSNYS_CLASS,className,classContent];
                                }
                                break;
                        }
                        
                    }
                }else if ([subObject isKindOfClass:[NSArray class]]){
                    id firstValue = nil;
                    NSString * classContent = nil;
                    if (((NSArray *)subObject).count > 0) {
                        firstValue = ((NSArray *)subObject).firstObject;
                    }else {
                        goto ARRAY_PASER;
                    }
                    if ([firstValue isKindOfClass:[NSString class]] ||
                        [firstValue isKindOfClass:[NSNumber class]]) {
                        if ([firstValue isKindOfClass:[NSString class]]) {
                            if(!self.isSwift){
                                [property appendFormat:kNYS_PROPERTY('c'),[NSString stringWithFormat:@"NSArray<%@ *>",@"NSString"],key];
                            }else{
                                [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",@"String"]];
                                [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                            }
                        }else {
                            if(!self.isSwift){
                                [property appendFormat:kNYS_PROPERTY('c'),[NSString stringWithFormat:@"NSArray<%@ *>",@"NSNumber"],key];
                            }else{
                                [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                                if (strcmp([firstValue objCType], @encode(float)) == 0 ||
                                    strcmp([firstValue objCType], @encode(CGFloat)) == 0) {
                                    [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",@"CGFloat"]];
                                }else if (strcmp([firstValue objCType], @encode(double)) == 0) {
                                    [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",@"double"]];
                                }else if (strcmp([firstValue objCType], @encode(BOOL)) == 0) {
                                    [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",@"Bool"]];
                                }else {
                                    [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",@"Int"]];
                                }
                            }
                        }
                    }else {
                    ARRAY_PASER:
                        classContent = [self handleDataEngine:subObject key:key];
                        if(!self.isSwift){
                            [property appendFormat:kNYS_PROPERTY('c'),[NSString stringWithFormat:@"NSArray<%@ *>",className],propertyName];
                            if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                [_classString appendFormat:kNYS_CodingAndCopyingCLASS,className,classContent];
                            }else if (_codingCheckBox.state != 0) {
                                [_classString appendFormat:kNYS_CodingCLASS,className,classContent];
                            }else if (_copyingCheckBox.state != 0) {
                                [_classString appendFormat:kNYS_CopyingCLASS,className,classContent];
                            }else if (_classBaseNYSBox.state != 0) {
                                [_classString appendFormat:kNYS_BASE_CLASS,className,classContent];
                            }else {
                                [_classString appendFormat:kNYS_CLASS,className,classContent];
                            }
                            if (_classPrefixName.length > 0) {
                                [_classMString appendFormat:kNYS_CLASS_Prefix_M,className,_classPrefixName];
                            }else {
                                if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                    [_classMString appendFormat:kNYS_CodingAndCopyingCLASS_M,className];
                                }else if (_codingCheckBox.state != 0) {
                                    [_classMString appendFormat:kNYS_CodingCLASS_M,className];
                                }else if (_copyingCheckBox.state != 0) {
                                    [_classMString appendFormat:kNYS_CopyingCLASS_M,className];
                                }else {
                                    [_classMString appendFormat:kNYS_CLASS_M,className];
                                }
                            }
                        }else{
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,[NSString stringWithFormat:@"[%@]",className]];
                            switch (_modelType) {
                                case SexyJson_class:
                                    if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                        [_classString appendFormat:kSexyJson_CodingAndCopyingCLASS,className,classContent];
                                    }else if (_codingCheckBox.state != 0) {
                                        
                                        [_classString appendFormat:kSexyJson_CodingCLASS,className,classContent];
                                    }else if (_copyingCheckBox.state != 0) {
                                        [_classString appendFormat:kSexyJson_CopyingCLASS,className,classContent];
                                    }else {
                                        [_classString appendFormat:kSexyJson_Class,className,classContent];
                                    }
                                    [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                                    break;
                                case SexyJson_struct:
                                    [_classString appendFormat:kSexyJson_Struct,className,classContent];
                                    [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                                    break;
                                case SwiftExCodable:
                                    [_classString appendFormat:kExCodable_Struct,className,classContent];
                                    break;
                                default:
                                    if (_codingCheckBox.state != 0 && _copyingCheckBox.state != 0) {
                                        [_classString appendFormat:kSNYS_CodingAndCopyingCLASS,className,classContent];
                                    }else if (_codingCheckBox.state != 0) {
                                        
                                        [_classString appendFormat:kSNYS_CodingCLASS,className,classContent];
                                    }else if (_copyingCheckBox.state != 0) {
                                        [_classString appendFormat:kSNYS_CopyingCLASS,className,classContent];
                                    }else {
                                        [_classString appendFormat:_classBaseNYS ? kYYModel_Swift_CLASS : kSNYS_CLASS,className,classContent];
                                    }
                                    break;
                            }
                        }
                    }
                }else if ([subObject isKindOfClass:[NSString class]]){
                    if(!self.isSwift){
                        [property appendFormat:kNYS_PROPERTY('c'),@"NSString",propertyName];
                    }else{
                        [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,@"String"];
                        [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                    }
                }else if ([subObject isKindOfClass:[NSNumber class]]){
                    if(!self.isSwift){
                        if (strcmp([subObject objCType], @encode(float)) == 0 ||
                            strcmp([subObject objCType], @encode(CGFloat)) == 0) {
                            [property appendFormat:kNYS_ASSIGN_PROPERTY,@"CGFloat",propertyName];
                        }else if (strcmp([subObject objCType], @encode(double)) == 0) {
                            [property appendFormat:kNYS_ASSIGN_PROPERTY,@"double",propertyName];
                        }else if (strcmp([subObject objCType], @encode(BOOL)) == 0) {
                            [property appendFormat:kNYS_ASSIGN_PROPERTY,@"BOOL",propertyName];
                        }else {
                            [property appendFormat:kNYS_ASSIGN_PROPERTY,@"NSInteger",propertyName];
                        }
                    }else{
                        [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                        if (strcmp([subObject objCType], @encode(float)) == 0 ||
                            strcmp([subObject objCType], @encode(CGFloat)) == 0) {
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_ASSGIN_PROPERTY : kSNYS_ASSGIN_PROPERTY,propertyName,@"CGFloat = 0.0"];
                        }else if (strcmp([subObject objCType], @encode(double)) == 0) {
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_ASSGIN_PROPERTY : kSNYS_ASSGIN_PROPERTY,propertyName,@"Double = 0.0"];
                        }else if (strcmp([subObject objCType], @encode(BOOL)) == 0) {
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_ASSGIN_PROPERTY : kSNYS_ASSGIN_PROPERTY,propertyName,@"Bool = false"];
                        }else {
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_ASSGIN_PROPERTY : kSNYS_ASSGIN_PROPERTY,propertyName,@"Int = 0"];
                        }
                    }
                }else{
                    if(subObject == nil){
                        if(!self.isSwift){
                            [property appendFormat:kNYS_PROPERTY('c'),@"NSString",propertyName];
                        }else{
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,@"String"];
                            [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                        }
                    }else if([subObject isKindOfClass:[NSNull class]]){
                        if(!self.isSwift){
                            [property appendFormat:kNYS_PROPERTY('c'),@"NSString",propertyName];
                        }else{
                            [property appendFormat:_modelType == SwiftExCodable ? kSENYS_PROPERTY : kSNYS_PROPERTY,propertyName,@"String"];
                            [propertyMap appendFormat:kSexyJson_Map,propertyName,key];
                        }
                    }
                }
            }];
        }else if ([object isKindOfClass:[NSArray class]]){
            NSArray  * dictArr = object;
            NSUInteger  count = dictArr.count;
            if(count){
                NSObject  * tempObject = dictArr[0];
                for (NSInteger i = 0; i < dictArr.count; i++) {
                    NSObject * subObject = dictArr[i];
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSDictionary *)subObject).count > ((NSDictionary *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSArray *)subObject).count > ((NSArray *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                }
                [property appendString:[self handleDataEngine:tempObject key:key]];
            }
        }else{
            NSLog(@"key = %@",key);
        }
        switch (_modelType) {
            case SexyJson_struct:
                if (![property containsString:@"public mutating func sexyMap(_ map: [String : Any])"]) {
                    [property appendFormat:kSexyJson_Struct_FuncMap,[self autoAlign:propertyMap]];
                }
                break;
            case SexyJson_class:
                if (![property containsString:@"public func sexyMap(_ map: [String : Any])"]) {
                    [property appendFormat:kSexyJson_FuncMap,[self autoAlign:propertyMap]];
                }
                break;
            default:
                break;
        }
        return property;
    }
    return @"";
}

- (NSString *)autoAlign:(NSString *)content {
    NSMutableString * newContent = [NSMutableString new];
    if (content) {
        NSArray * rows = [content componentsSeparatedByString:@"\n"];
        NSInteger maxLen = 0;
        for (NSString * row in rows) {
            NSRange range = [row rangeOfString:@"<<<"];
            if (range.location != NSNotFound) {
                maxLen = MAX([row rangeOfString:@"<<<"].location, maxLen);
            }
        }
        for (NSString * row in rows) {
            NSInteger rowindex = [row rangeOfString:@"<<<"].location;
            if (rowindex < maxLen && rowindex != NSNotFound) {
                NSInteger dindex = maxLen - rowindex;
                NSMutableString * blank = [NSMutableString new];
                for (int i = 0; i < dindex; i++) {
                    [blank appendString:@" "];
                }
                NSMutableString * mrow = row.mutableCopy;
                [mrow insertString:blank atIndex:rowindex];
                [newContent appendString:mrow];
                [newContent appendString:@"\n"];
            }else {
                [newContent appendString:row];
                [newContent appendString:@"\n"];
            }
        }
    }
    return newContent;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
}

@end

