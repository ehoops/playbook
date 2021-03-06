//
//  ViewController.m
//  Playbook
//
//  Created by Erin Hoops on 7/21/16.
//  Copyright © 2016 Erin Hoops. All rights reserved.
//

#import "ViewController.h"
#import "BBLMarkerView.h"
#import "BBLArrowView.h"
#import "BBLDataModel.h"


@interface ViewController ()

@end

@implementation ViewController {
    // Court, markers and arrows
    UIImageView *_courtView;
    NSArray<BBLMarkerData *> *_markers;
    BBLArrowView *_arrowView;
    NSMutableArray *_pathPoints;
    
    // Buttons
    UIButton *_resetButton;
    UIButton *_recordButton;
    UIButton *_stepButton;
    UIButton *_defenseButton;
    UIButton *_saveButton;
    UIButton *_loadButton;
    
    // Button controls
    BOOL _recording;
    BOOL _showDefense;
    
    // Recording and play back
    BBLSnapshot *_snapshot;
    BBLPlay *_play;
    int _stepCount;
    
    // Saving and loading plays
    NSData *_savedPlay;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Setup background
    _courtView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"court"]];
    _courtView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_courtView];
    self.view.backgroundColor = [UIColor whiteColor];

    // Setup Arrow layer
    CGRect bounds = self.view.bounds;
    _pathPoints = [NSMutableArray new];
    _arrowView = [[BBLArrowView alloc] initWithFrame:bounds];
    [self.view addSubview:_arrowView];

    
    // Reset Button
    _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [_resetButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _resetButton.backgroundColor = [UIColor grayColor];
    [_resetButton addTarget:self action:@selector(_resetButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_resetButton];
    
    // Record Button
    _recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [_recordButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _recordButton.backgroundColor = [UIColor grayColor];
    [_recordButton addTarget:self action:@selector(_recordButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_recordButton];
    
    // Step Button
    _stepButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_stepButton setTitle:@"Step" forState:UIControlStateNormal];
    [_stepButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_stepButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _stepButton.backgroundColor = [UIColor grayColor];
    [_stepButton addTarget:self action:@selector(_stepButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_stepButton];
    
    // Show Defense Button
    _defenseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_defenseButton setTitle:@"Defense" forState:UIControlStateNormal];
    [_defenseButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_defenseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _defenseButton.backgroundColor = [UIColor grayColor];
    [_defenseButton addTarget:self action:@selector(_defenseButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_defenseButton];
    
    // Save Button
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [_saveButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _saveButton.backgroundColor = [UIColor grayColor];
    [_saveButton addTarget:self action:@selector(_saveButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_saveButton];
    
    // Load Button
    _loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_loadButton setTitle:@"Load" forState:UIControlStateNormal];
    [_loadButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [_loadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _loadButton.backgroundColor = [UIColor grayColor];
    [_loadButton addTarget:self action:@selector(_loadButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loadButton];
    
    _showDefense = YES;
    _recording = NO;
    _play = [BBLPlay new];
    _stepCount = -1;
    
    
    // Setup Player and Ball markers
    // Two teams of 5 and 1 ball
    NSMutableArray *markers = [NSMutableArray new];

    // Create Offense Markers - markers[0-4]
    for (int i=0; i < 5; i++) {
        BBLMarkerData *marker = [self _createMarkerWithColor:[UIColor blueColor] position:CGPointMake(CGRectGetMidX(bounds) - i * 50 + 100, CGRectGetMidY(bounds) - 150) size:CGSizeMake(35, 35) team:1];
        [markers addObject:marker];
    }
    // Create Defense Markers - markers[5-9]
    for (int i=0; i < 5; i++) {
        BBLMarkerData *marker = [self _createMarkerWithColor:[UIColor redColor] position:CGPointMake(CGRectGetMidX(bounds) - i * 50 + 100, CGRectGetMidY(bounds) - 75) size:CGSizeMake(35, 35) team:2];
        [markers addObject:marker];
    }
    
    // Create Ball Marker - markers[10]
    BBLMarkerData *marker = [self _createMarkerWithColor:[UIColor brownColor] position:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)) size:CGSizeMake(25, 25) team:0];
    [markers addObject:marker];
    
    _markers = [markers copy];
    [self _saveSnapshot];
}

- (void)viewWillLayoutSubviews {
    // Layout court
    CGSize backgroundSize = self.view.bounds.size;
    CGSize courtSize = backgroundSize;
    courtSize.height -= 15;
    CGSize imageSize = _courtView.image.size;
    courtSize.width = courtSize.height * imageSize.width / imageSize.height;
    _courtView.frame = CGRectMake(backgroundSize.width - courtSize.width,
                                  backgroundSize.height - courtSize.height,
                                  courtSize.width, courtSize.height);
    _arrowView.frame = self.view.bounds;
    
    // Layout buttons
    _resetButton.frame = CGRectMake(10, 160, backgroundSize.width - courtSize.width - 20, 100);
    _recordButton.frame = CGRectMake(10, 280, backgroundSize.width - courtSize.width - 20, 100);
    _stepButton.frame = CGRectMake(10, 400, backgroundSize.width - courtSize.width - 20, 100);
    _defenseButton.frame = CGRectMake(10, 520, backgroundSize.width - courtSize.width - 20, 100);
    _saveButton.frame = CGRectMake(10, 640, backgroundSize.width - courtSize.width - 20, 100);
    _loadButton.frame = CGRectMake(10, 760, backgroundSize.width - courtSize.width - 20, 100);

    // Update marker positions and lay them out
    for (BBLMarkerData *marker in _markers) {
        if (!_showDefense && marker.team == 2) {
            marker.view.hidden = YES;
            // TODO Make view unselectable
        } else {
            marker.view.hidden = NO;
            // TODO Make view selectable
        }
        marker.view.center = CGPointMake(marker.markerPosition.x + marker.markerPositionDelta.x,
                                         marker.markerPosition.y + marker.markerPositionDelta.y);
        marker.view.bounds = CGRectMake(0, 0, marker.markerSize.width, marker.markerSize.height);
    }
}

// Helper method to create a player or ball marker
- (BBLMarkerData *)_createMarkerWithColor:(UIColor *)color position:(CGPoint)position size:(CGSize)size team:(int)team {
    BBLMarkerData *marker = [[BBLMarkerData alloc] init];
    [self.view addSubview:marker.view];
    marker.color = color;
    marker.markerPosition = position;
    marker.markerSize = size;
    marker.team = team;
    
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_onPan:)];
    [marker.view addGestureRecognizer:panGR];
    return marker;
}

// Helper method to save the marker position and current arrow (pathPoints)
- (void)_saveSnapshot {
    BBLSnapshot *snapshot = [[BBLSnapshot alloc] init];
    NSMutableArray *tempPositions = [[NSMutableArray alloc] init];
    for (BBLMarkerData *marker in _markers) {
        [tempPositions addObject:[NSValue valueWithCGPoint:marker.markerPosition]];
    }
    snapshot.snapPositions = tempPositions;
    snapshot.snapPath = _arrowView.pathPoints;
    _snapshot = snapshot;
}

// Helper method to save the current snapshot to the play series
- (void) _addPlayStep {
    [self _saveSnapshot];
    NSMutableArray *currentPlaySteps = [_play.playSteps mutableCopy];
    [currentPlaySteps addObject:_snapshot];
    _play.playSteps = currentPlaySteps;
}

// Helper method for reset marker positions
- (void) _setMarkersWithSnapshot:(BBLSnapshot *)snap {
    _arrowView.pathPoints = @[];
    for (int i = 0; i < _markers.count; i++) {
        NSValue *resetPosition = snap.snapPositions[i];
        [_markers[i] setMarkerPosition:resetPosition.CGPointValue];
    }
    return;
}

// Helper method to toggle recording
- (void) _stopRecording
{
    NSAssert(_recording, @"Tried to stop recording when recording was off.");
    [_recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _recordButton.backgroundColor = [UIColor grayColor];
    _recording = NO;
}

// Gesture and button click methods
- (void)_onPan:(UIPanGestureRecognizer *)panGR {
    NSUInteger index = [_markers indexOfObjectPassingTest:^BOOL(BBLMarkerData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.view == panGR.view;
    }];
    
    if (index == NSNotFound) {
        return;
    }
    BBLMarkerData *marker = _markers[index];
    CGPoint p = [panGR translationInView:self.view];
    
    if (panGR.state == UIGestureRecognizerStateBegan) {
        [_pathPoints removeAllObjects];
        [_pathPoints addObject:[NSValue valueWithCGPoint:CGPointMake(marker.markerPosition.x,
                                                                     marker.markerPosition.y)]];
    } else if (panGR.state == UIGestureRecognizerStateEnded) {
        marker.markerPosition = CGPointMake(marker.markerPosition.x + p.x,
                                            marker.markerPosition.y + p.y);
        marker.markerPositionDelta = CGPointZero;
        // Need to record step after positions are updated
        if (_recording) {
            [self _addPlayStep];
        }
    } else {
        marker.markerPositionDelta = p;
        [_pathPoints addObject:[NSValue valueWithCGPoint:CGPointMake(marker.markerPosition.x + p.x, marker.markerPosition.y + p.y)]];
    }
    _arrowView.pathPoints = _pathPoints;
    [self.view setNeedsLayout];
}

// Button Click Methods
- (void)_resetButtonAction
{
    if (_recording) {
        [self _stopRecording];
    }
    BBLSnapshot *start = [BBLSnapshot new];
    if ([_play.playSteps count] > 0) {
        start = _play.playSteps[0];
    } else {
        start = _snapshot;
    }
    [self _setMarkersWithSnapshot:start];
    _stepCount = 1;
    [self.view setNeedsLayout];

}

- (void)_recordButtonAction
{
    if (!_recording) {
        _play.playSteps = @[];
        _stepCount = 0;
        [self _addPlayStep];
        [_recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _recordButton.backgroundColor = [UIColor redColor];
        _recording = YES;
    } else {
        [self _stopRecording];
    }
}

- (void)_stepButtonAction
{
    if (_recording) {
        [self _stopRecording];
    }
    if (_stepCount == -1) {
        return;
    }
    if (_stepCount == 0) {
        [self _setMarkersWithSnapshot:_play.playSteps[0]];
    } else if (_stepCount >= [_play.playSteps count]) {
        _stepCount = 0;
        [self _setMarkersWithSnapshot:_play.playSteps[0]];
    } else {
        BBLSnapshot *step = _play.playSteps[_stepCount];
        [self _setMarkersWithSnapshot:step];
        _arrowView.pathPoints = step.snapPath;
    }
    _stepCount += 1;
    [self.view setNeedsLayout];
}

- (void)_defenseButtonAction
{
    if (!_showDefense) {
        [_defenseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _defenseButton.backgroundColor = [UIColor blueColor];
        _showDefense = YES;
    } else {
        [_defenseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _defenseButton.backgroundColor = [UIColor grayColor];
        _showDefense = NO;
    }
    // Clicking the show defense button clears the most recent arrow
    // Non-optimal solution, but avoids showing an orphan arrow if the
    // defense moves last before hiding
    _arrowView.pathPoints = @[];
    [self.view setNeedsLayout];
}

- (void)_saveButtonAction
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_play];
    _savedPlay = data;
}

- (void)_loadButtonAction
{
    if (_savedPlay == nil) {
        return;
    }
    if (_recording) {
        [self _stopRecording];
    }
    _play = [NSKeyedUnarchiver unarchiveObjectWithData:_savedPlay];
    
    [self _setMarkersWithSnapshot:_play.playSteps[0]];
    _stepCount = 1;
    [self.view setNeedsLayout];
}
@end
