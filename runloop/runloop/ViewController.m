//
//  ViewController.m
//  runloop
//
//  Created by wdwk on 2017/6/20.
//  Copyright © 2017年 wksc. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"

typedef void(^RunloopBlock)();
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
//强引用只是保住了OC对象，但并没有真实的保住这条线程！线程是CPU去调用，和OC对象没有关系，所以要保住线程只能通过runloop来保住线程；
@property(nonatomic,strong)NSThread *thread;
@property(nonatomic,strong)dispatch_source_t timer;
@property(nonatomic,strong)UITableView * exampleTableView;
//超出屏幕之外的任务我们就不需要添加到任务数组中去了，所以定义一个最大的任务数
@property(nonatomic,assign)NSInteger maxQueue;
//图片加载的任务数组；
@property(nonatomic,strong)NSMutableArray *tasks;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    GCD的timer
    _maxQueue=18;
    _tasks=[NSMutableArray new];
    self.exampleTableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 550) style:UITableViewStylePlain];
    [self.view addSubview:self.exampleTableView];
    self.exampleTableView.delegate=self;
    self.exampleTableView.dataSource=self;
    [self.exampleTableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    [self addRunloopObserver];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return  200;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPat{
    return 153;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
//    cell.imageView1.image=[UIImage imageNamed:@"22.jpg"];
//    cell.imageView2.image=[UIImage imageNamed:@"22.jpg"];
//    cell.imageView3.image=[UIImage imageNamed:@"22.jpg"];
    [self addTask:^{
        cell.imageView1.image=[UIImage imageNamed:@"22.jpg"];
    }];
    [self addTask:^{
         cell.imageView2.image=[UIImage imageNamed:@"22.jpg"];
    }];
    [self addTask:^{
        cell.imageView3.image=[UIImage imageNamed:@"22.jpg"];
    }];
    return cell;
}
#pragma mark-关于runloop的函数；
//定义一个添加任务的方法
-(void)addTask:(RunloopBlock)task{
    [self.tasks addObject:task];
//    如果添加的任务tasks的长度大于最大任务数，则删除第0个任务，保证之前没来得及显示的Cell不会绘制图片了；
    if (self.tasks.count>self.maxQueue) {
        [self.tasks removeObjectAtIndex:0];
    }
}

-(void)addRunloopObserver{
//获取当前的runloop
   CFRunLoopRef runloop=CFRunLoopGetCurrent();
//    定义一个上下文
//    typedef struct {
//        CFIndex	version;
//        void *	info;这是一个万能指针，所以我们传递当前控制器，以便Core Foundation能够操作；而OC 要跟C交互(__bridge void *)桥接一下
//        const void *(*retain)(const void *info);
//        void	(*release)(const void *info);
//        CFStringRef	(*copyDescription)(const void *info);
//    } CFRunLoopObserverContext;

    CFRunLoopObserverContext context={
        0,
       (__bridge void *) self,
        &CFRetain,
        &CFRelease,
        NULL
        
    };
//    定义一个观察者
    static CFRunLoopObserverRef defaultModelObserver;
//    通过函数创建观察者；第四个参数是一个函数指针，而且是带参数的函数typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);，需要传递一个函数的地址，所以我们要定义一个函数
  defaultModelObserver=  CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0, &CallBack, &context);
//    添加观察者
    CFRunLoopAddObserver(runloop, defaultModelObserver, kCFRunLoopCommonModes);
    
//    c语言中使用了create，就要release;
    CFRelease(defaultModelObserver);
}
static void CallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    NSLog(@"来了");
    ViewController* VC=(__bridge ViewController *) info;
    if (VC.tasks.count==0) {
        return;
    }
//    for (int i=0 ; i<VC.tasks.count; i++) {
//        拿出任务
        RunloopBlock task=VC.tasks.firstObject;
//        执行任务
        task();
//        干掉任务
        [VC.tasks  removeObjectAtIndex:0];
//    }
    
    //处理控制器的加载图片的事情；
//    先拿到我们的控制器，那么怎样把我们的图片加载分布到这个函数，这就要用到我们的block;
    
}

-(void)timerMethod{
    NSLog(@"come here");
    [NSThread sleepForTimeInterval:1.0];
}
-(void)Demo3{
    //    创建事件源： 按照函数调用栈，分为：source0(非系统内核事件),source1（系统内核事件）;
    self.timer=  dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    //设置timer的时间,GCD是C语言的，所以时间单位是纳秒，1秒=1000毫秒=1000 000微妙=1000 000 000纳秒=1.0*NSEC_PER_SEC；
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1000000000, 0);
    //设置回调
    dispatch_source_set_event_handler(self.timer, ^{
        NSLog(@"----%@",[NSThread currentThread]);
        
    });
    //    启动timer;
    dispatch_resume(self.timer);
}
-(void)Demo1{

    //此方法中timer 会被自动添加到runloop中；
    //    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
    //这个方法需要手动将timer添加到runloop中；
    NSTimer *timer= [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
    // 将timer添加到runloop中去；[NSRunLoop currentRunLoop]返回当前线程的runloop;此时当前线程是主线程；
    //        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    //        [[NSRunLoop currentRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}
-(void)Demo2{
    self. thread= [[NSThread alloc]initWithBlock:^{
        
        
        NSTimer *timer= [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
        // 将timer添加到主线程runloop中去；[NSRunLoop currentRunLoop]返回当前线程的runloop;此时当前线程是主线程；
        NSLog(@"====%@",[NSThread currentThread]);
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        //            [[NSRunLoop currentRunLoop]run];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        //当runloop被开启了，这里就出现死循环，所以“来了”这句话就不能执行；
        NSLog(@"来了");
        
    }];
    [self.thread start];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
