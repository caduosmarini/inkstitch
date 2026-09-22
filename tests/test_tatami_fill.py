from shapely import geometry as shgeo

from lib.stitches.tatami_fill import PathEdge, fill_gap, fill_gaps


def _path_ending_in_rows(penultimate, last):
    return [
        PathEdge(penultimate, "segment"),
        PathEdge((penultimate[1], last[0]), "outline"),
        PathEdge(last, "segment"),
    ]


def _assert_edges_covered(shape, edges):
    buffered_shape = shape.buffer(1e-9)
    for edge in edges:
        assert buffered_shape.covers(shgeo.LineString(edge.nodes))


def test_fill_gaps_zero_preserves_original_path():
    path = _path_ending_in_rows(((9, 2), (1, 2)), ((1, 3), (9, 3)))

    assert fill_gaps(path, 0, shgeo.box(0, 0, 10, 10)) is path


def test_fill_gap_clips_rows_to_curved_outline():
    shape = shgeo.Point(5, 5).buffer(5)
    path = _path_ending_in_rows(((8, 6), (2, 6)), ((2, 7), (8, 7)))
    original_length = len(path)

    fill_gap(path, 2, shape)

    added = path[original_length:]
    assert added
    _assert_edges_covered(shape, added)
    outer_row_points = [
        point for edge in added for point in edge.nodes if point[1] == 9
    ]
    assert min(point[0] for point in outer_row_points) > 2
    assert max(point[0] for point in outer_row_points) < 8


def test_fill_gap_does_not_cross_hole_when_row_splits():
    shape = shgeo.Polygon(
        [(0, 0), (10, 0), (10, 10), (0, 10)],
        holes=[[(4, 4), (6, 4), (6, 6), (4, 6)]],
    )
    path = _path_ending_in_rows(((9, 2.5), (1, 2.5)), ((1, 3.5), (9, 3.5)))
    original_length = len(path)

    fill_gap(path, 2, shape)

    added = path[original_length:]
    assert added
    _assert_edges_covered(shape, added)
    # The reachable component is on the right of the hole.  The algorithm
    # must not join it to the disconnected component on the left.
    assert min(point[0] for edge in added for point in edge.nodes) >= 6


def test_fill_gap_skips_pair_when_it_cannot_return_inside_shape():
    shape = shgeo.Polygon([(0, 0), (10, 0), (10, 4), (4, 4), (4, 10), (0, 10)])
    path = _path_ending_in_rows(((3, 2), (1, 2)), ((1, 3), (3, 3)))
    original = list(path)

    fill_gap(path, 4, shape)

    _assert_edges_covered(shape, path[len(original):])
    assert path[:len(original)] == original
