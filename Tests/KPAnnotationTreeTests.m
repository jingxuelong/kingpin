//
//  kingpinTests.m
//  kingpinTests
//
//  Created by Stanislaw Pankevich on 08/03/14.
//
//

#import "TestHelpers.h"

#import "KPAnnotationTree.h"
#import "KPAnnotationTree_Private.h"

#import "TestAnnotation.h"

#import "Datasets.h"

@interface KPAnnotationTree_Queries_Test : XCTestCase
@end

@implementation KPAnnotationTree_Queries_Test

- (void)test_trivial_emptyTree {
    KPAnnotationTree *emptyTree = [[KPAnnotationTree alloc] initWithAnnotations:@[]];

    NSArray *annotations = [emptyTree annotationsInMapRect:MKMapRectWorld];

    XCTAssertTrue([annotations isKindOfClass:[NSArray class]]);
    XCTAssertEqual(annotations.count, 0);
}

- (void)test_trivial_treeWithOneAnnotation {
    TestAnnotation *annotation = [[TestAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(15, 15);

    KPAnnotationTree *treeWithOneAnnotation = [[KPAnnotationTree alloc] initWithAnnotations:@[ annotation ]];

    NSArray *annotations = [treeWithOneAnnotation annotationsInMapRect:MKMapRectWorld];

    TestAnnotation *annotationBySearch = [annotations firstObject];

    XCTAssertTrue([annotationBySearch isEqual:annotation]);
    XCTAssertTrue([annotations isKindOfClass:[NSArray class]]);
    XCTAssertTrue(annotations.count == 1);
}

- (void)test_trivial_twoPoints {
    CLLocationCoordinate2D coordinate1 = MKCoordinateForMapPoint(MKMapPointMake(0, 0));
    CLLocationCoordinate2D coordinate2 = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectWorld.size.width, MKMapRectWorld.size.height));

    TestAnnotation *annotation1 = [[TestAnnotation alloc] init];
    annotation1.coordinate = coordinate1;

    TestAnnotation *annotation2 = [[TestAnnotation alloc] init];
    annotation2.coordinate = coordinate2;

    KPAnnotationTree *tree = [[KPAnnotationTree alloc] initWithAnnotations:@[
        annotation1,
        annotation2
    ]];

    NSArray *annotations = [tree annotationsInMapRect:MKMapRectWorld];
    
    XCTAssertTrue(annotations.count == 2);
}

- (void)test_edge_twoPoints_for_larger_MKMapRectWorld {
    CLLocationCoordinate2D coordinate1 = MKCoordinateForMapPoint(MKMapPointMake(0, 0));
    CLLocationCoordinate2D coordinate2 = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectWorld.size.width, MKMapRectWorld.size.height));

    TestAnnotation *annotation1 = [[TestAnnotation alloc] init];
    annotation1.coordinate = coordinate1;

    TestAnnotation *annotation2 = [[TestAnnotation alloc] init];
    annotation2.coordinate = coordinate2;

    KPAnnotationTree *tree = [[KPAnnotationTree alloc] initWithAnnotations:@[
                                                                             annotation1,
                                                                             annotation2
                                                                             ]];

    MKMapRect largerMapRectWorld = MKMapRectMake(-DBL_MAX / 4, -DBL_MAX / 4, DBL_MAX / 2, DBL_MAX / 2);

    NSArray *annotations = [tree annotationsInMapRect:largerMapRectWorld];

    XCTAssertTrue(annotations.count == 2);
}

- (void)test_edge_mapRectSpanningOverInternationalDateline {
    double irrelevantY = MKMapRectWorld.size.height / 2;

    CLLocationCoordinate2D coordinateCloseToLeftEdge = MKCoordinateForMapPoint(MKMapPointMake(1, irrelevantY));
    CLLocationCoordinate2D coordinateCloseToRightEdge = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectWorld.size.width - 1, irrelevantY));

    TestAnnotation *annotationCloseToLeftEdge = [[TestAnnotation alloc] init];
    annotationCloseToLeftEdge.coordinate = coordinateCloseToLeftEdge;

    TestAnnotation *annotationCloseToRightEdge = [[TestAnnotation alloc] init];
    annotationCloseToRightEdge.coordinate = coordinateCloseToRightEdge;

    KPAnnotationTree *tree = [[KPAnnotationTree alloc] initWithAnnotations:@[
        annotationCloseToLeftEdge,
        annotationCloseToRightEdge
    ]];

    MKMapRect spanningMapRect = MKMapRectMake(
        MKMapRectWorld.size.width - 2,
        irrelevantY - 1,
        4,
        2
    );

    NSArray *annotations = [tree annotationsInMapRect:spanningMapRect];

    XCTAssertTrue(annotations.count == 2);
}

@end

@interface KPAnnotationTree_Integration_Test : XCTestCase
@end

@implementation KPAnnotationTree_Integration_Test

typedef struct {
    kp_treenode_t *node;
    int level;
} kp_stack_el_t;

- (void)testTreesWithVariousNumberOfAnnotations {
    NSUInteger K = 100;
    NSUInteger N = 100;

    NSUInteger iterationsCount = 0;
    for (NSUInteger i = 0; i < N; i++) {
        for (NSUInteger j = 0; j < K; j++) {
            iterationsCount++;

            NSArray *annotations = [KPTestDatasets datasetRandomWithNumberOfAnnotations:i];

            KPAnnotationTree *annotationTree = [[KPAnnotationTree alloc] initWithAnnotations:annotations];

            NSArray *annotationsBySearch = [annotationTree annotationsInMapRect:MKMapRectWorld];

            for (id <MKAnnotation> annotation in annotationsBySearch) {
                XCTAssertTrue([annotation isKindOfClass:[TestAnnotation class]]);
                XCTAssertTrue(CLLocationCoordinate2DIsValid([annotation coordinate]));
            }

            NSSet *annotationsBySearchSet = [NSSet setWithArray:annotationsBySearch];

            XCTAssertTrue([annotationsBySearchSet isEqualToSet:annotationTree.annotations]);
            XCTAssertTrue(annotations.count == annotations.count);
        }
    }

    XCTAssertTrue(iterationsCount == K * N);
}

- (void)test_edge_treesWithVariousNumberOfEqualAnnotations {
    NSUInteger K = 100;
    NSUInteger N = 100;

    NSUInteger iterationsCount = 0;
    for (NSUInteger i = 0; i < N; i++) {
        for (NSUInteger j = 0; j < K; j++) {
            iterationsCount++;

            NSArray *annotations = [KPTestDatasets datasetRandomWithNumberOfEqualAnnotations:i];

            KPAnnotationTree *annotationTree = [[KPAnnotationTree alloc] initWithAnnotations:annotations];

            NSArray *annotationsBySearch = [annotationTree annotationsInMapRect:MKMapRectWorld];

            for (id <MKAnnotation> annotation in annotationsBySearch) {
                XCTAssertTrue([annotation isKindOfClass:[TestAnnotation class]]);
                XCTAssertTrue(CLLocationCoordinate2DIsValid([annotation coordinate]));
            }

            NSSet *annotationsBySearchSet = [NSSet setWithArray:annotationsBySearch];

            XCTAssertTrue([annotationsBySearchSet isEqualToSet:annotationTree.annotations]);
            XCTAssertTrue(annotations.count == annotations.count);
        }
    }

    XCTAssertTrue(iterationsCount == K * N);
}

- (void)testIntegrityOfAnnotationTree {
    id datasets = [KPTestDatasets datasets];

    for (NSArray *annotations in datasets) {
        NSUInteger annotationsCount = annotations.count;

        NSLog(@"Annotation Count: %tu", annotationsCount);

        KPAnnotationTree *annotationTree = [[KPAnnotationTree alloc] initWithAnnotations:annotations];

        NSArray *annotationsBySearch = [annotationTree annotationsInMapRect:MKMapRectWorld];

        XCTAssertTrue(NSArrayHasDuplicates(annotationsBySearch) == NO);

        __block NSUInteger numberOfNodes = 0;

        void (^traversalBlock)(kp_treenode_t *, int) = ^(kp_treenode_t *node, int level) {
            NSUInteger XorY = (level % 2) == 0;

            if (node->left) {
                if (XorY) {
                    XCTAssertTrue(node->left->mk_map_point.x < node->mk_map_point.x, @"");
                } else {
                    XCTAssertTrue(node->left->mk_map_point.y < node->mk_map_point.y, @"");
                }
            }

            if (node->right) {
                if (XorY) {
                    XCTAssertTrue(node->mk_map_point.x <= node->right->mk_map_point.x, @"");
                } else {
                    XCTAssertTrue(node->mk_map_point.y <= node->right->mk_map_point.y, @"");
                }
            }
        };

        kp_stack_el_t *stack_info_storage = malloc(annotationsCount * sizeof(kp_stack_el_t));
        kp_stack_el_t *top_snaphot;

        kp_stack_t stack = kp_stack_create(annotationsCount);
        kp_stack_push(&stack, NULL);

        kp_stack_el_t *top = stack_info_storage;
        top->node = annotationTree.tree.root;
        top->level = 0;

        while (top != NULL) {
            numberOfNodes++;

            kp_treenode_t *node = top->node;

            traversalBlock(top->node, top->level);

            top_snaphot = top;

            if (node->right != NULL) {
                top++;

                (top)->node = node->right;
                (top)->level = top_snaphot->level + 1;;

                kp_stack_push(&stack, top);
            }

            if (node->left != NULL) {
                top++;

                (top)->node = node->left;
                (top)->level = top_snaphot->level + 1;;

                kp_stack_push(&stack, top);
            }

            top = kp_stack_pop(&stack);
        }

        NSLog(@"numberOfNodes Count: %tu", numberOfNodes);

        XCTAssertTrue(annotationsCount == annotations.count, @"");
        XCTAssertTrue(annotationsCount == annotationsBySearch.count, @"");
        XCTAssertTrue(annotationsCount == numberOfNodes, @"");
    }
}

- (void)testEquivalenceOfAnnotationTrees {
    id datasets = [KPTestDatasets datasets];

    for (NSArray *annotations in datasets) {
        NSUInteger annotationsCount = annotations.count;

        // Create array of shuffled annotations and ensure integrity.
        NSArray *shuffledAnnotations = arrayShuffle(annotations);

        NSAssert(annotations.count == shuffledAnnotations.count, nil);

        NSSet *annotationSet = [NSSet setWithArray:annotations];
        NSSet *shuffledAnnotationSet = [NSSet setWithArray:shuffledAnnotations];

        NSAssert([annotationSet isEqual:shuffledAnnotationSet], nil);

        // Build to two different trees based on original and shuffled annotations arrays.
        KPAnnotationTree *annotationTree1 = [[KPAnnotationTree alloc] initWithAnnotations:annotations];
        KPAnnotationTree *annotationTree2 = [[KPAnnotationTree alloc] initWithAnnotations:shuffledAnnotations];

        NSArray *annotationsBySearch1 = [annotationTree1 annotationsInMapRect:MKMapRectWorld];
        NSArray *annotationsBySearch2 = [annotationTree2 annotationsInMapRect:MKMapRectWorld];

        XCTAssertTrue(NSArrayHasDuplicates(annotationsBySearch1) == NO);
        XCTAssertTrue(NSArrayHasDuplicates(annotationsBySearch2) == NO);

        NSSet *annotationSetBySearch1 = [NSSet setWithArray:annotationsBySearch1];
        NSSet *annotationSetBySearch2 = [NSSet setWithArray:annotationsBySearch2];

        XCTAssertTrue([annotationSetBySearch1 isEqual:annotationSetBySearch2], @"");
        XCTAssertTrue([annotationSetBySearch1 isEqual:annotationSet], @"");
        XCTAssertTrue(annotationsBySearch1.count == annotationsCount, @"");

        // Create random rect
        MKMapRect randomRect = MKMapRectRandom();
        
        NSAssert(MKMapRectContainsRect(MKMapRectWorld, randomRect), nil);
        
        annotationsBySearch1 = [annotationTree1 annotationsInMapRect:randomRect];
        annotationsBySearch2 = [annotationTree2 annotationsInMapRect:randomRect];
        
        annotationSetBySearch1 = [NSSet setWithArray:annotationsBySearch1];
        annotationSetBySearch2 = [NSSet setWithArray:annotationsBySearch2];
        
        XCTAssertTrue([annotationSetBySearch1 isEqual:annotationSetBySearch2], @"");
    }
}

@end

