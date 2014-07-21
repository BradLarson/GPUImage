#import "GPUAudioPlayer.h"

#define NumAudioQueueBuffer  3
#define QueueBufferSize  2048

void GPUAudioQueueOutputCallback ( void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer );

@interface GPUAudioPlayer()

- (void)handleAudioQueueOutputCallback:(AudioQueueRef)audioQueue buffer:(AudioQueueBufferRef)buffer;

@end


void GPUAudioQueueOutputCallback ( void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer )
{
    GPUAudioPlayer *audioPlayer = (__bridge GPUAudioPlayer *)(inUserData);
    [audioPlayer handleAudioQueueOutputCallback:inAQ buffer:inBuffer];
}

@implementation GPUAudioPlayer
{
    AudioQueueRef _audioQueue;
    AudioQueueBufferRef _audioQueueBuffer[NumAudioQueueBuffer];
    BOOL _usedBuffer[NumAudioQueueBuffer];
    
    NSMutableData *_cacheData;
    UInt32 _cacheOffset;
    OSStatus _status;
    UInt32 _bufferSize;
    BOOL _doCancel;
    NSRecursiveLock *_lock;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _lock = [[NSRecursiveLock alloc] init];
    return self;
}
- (void)checkStatus
{
    if (_status) {
        NSLog(@"GPUAudio failed %lu",_status);
    }
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
{
    [_lock lock];
    if (!_doCancel) {
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioBuffer);
        size_t totalLength;
        char *dataPoint;
        CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totalLength, &dataPoint);
        if (!_cacheData) {
            _cacheData = [NSMutableData dataWithCapacity:1024*16];
        }
        [_cacheData appendBytes:dataPoint length:totalLength];
        if (!_audioQueue) {
            [self createAudioQueue:audioBuffer];
        }else{
            AudioQueueBufferRef buffer = [self checkNoUsedBuffer];
            if (buffer) {
                [self handleAudioQueueOutputCallback:_audioQueue buffer:buffer];
            }
        }
    }
    [_lock unlock];
}

- (void)createAudioQueue:(CMSampleBufferRef)audioBuffer
{
    [_lock lock];
    CMFormatDescriptionRef cmfd = CMSampleBufferGetFormatDescription(audioBuffer);
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(cmfd);
    _status = AudioQueueNewOutput(asbd, GPUAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    [self checkStatus];
    if (_audioQueue) {
        _bufferSize = QueueBufferSize;
        for (int i = 0; i < NumAudioQueueBuffer; ++i) {
            AudioQueueAllocateBuffer(_audioQueue, _bufferSize, &_audioQueueBuffer[i]);
            [self handleAudioQueueOutputCallback:_audioQueue buffer:_audioQueueBuffer[i]];
        }
        AudioQueueSetParameter(_audioQueue, kAudioQueueParam_Volume, 1.0);
        _status = AudioQueueStart(_audioQueue, 0);
        [self checkStatus];
    }
    [_lock unlock];
}

- (void)handleAudioQueueOutputCallback:(AudioQueueRef)audioQueue buffer:(AudioQueueBufferRef)buffer
{
    [_lock lock];
        size_t size = _bufferSize;
        if (_cacheData.length < _cacheOffset + size) {
            size = _cacheData.length - _cacheOffset;
        }
        if (size > 0) {
            [_cacheData getBytes:buffer->mAudioData range:NSMakeRange(_cacheOffset, size)];
            buffer->mAudioDataByteSize = size;
            _cacheOffset += size;
            AudioQueueEnqueueBuffer(audioQueue, buffer, 0, NULL);
        }else{
            NSLog(@"No data..... %d",_cacheData.length);
        }
        NSInteger index = [self bufferIndex:buffer];
        if (index >= 0) {
            _usedBuffer[index] = size > 0;
        }
    [_lock unlock];
}

- (NSInteger)bufferIndex:(AudioQueueBufferRef)buffer
{
    for (int i = 0; i < NumAudioQueueBuffer; ++i) {
        if (_audioQueueBuffer[i] == buffer) {
            return i;
        }
    }
    return -1;
}

- (AudioQueueBufferRef)checkNoUsedBuffer
{
    for (int i = 0; i < NumAudioQueueBuffer; ++i) {
        if (!_usedBuffer[i]) {
            return _audioQueueBuffer[i];
        }
    }
    return nil;
}

- (void)stopPlay
{
    [_lock lock];
    if (!_doCancel) {
        _doCancel = YES;
        if (_audioQueue) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                AudioQueueDispose(_audioQueue, YES);
            });
        }
    }
    [_lock unlock];
}

@end
