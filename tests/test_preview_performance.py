from threading import Event
from time import sleep

from lib.elements.element import EmbroideryElement
from lib.gui.simulator.simulator_renderer import PreviewRenderer


def test_preview_renderer_debounces_rapid_updates(monkeypatch):
    rendered = []
    completed = Event()

    def render():
        rendered.append(len(rendered) + 1)
        return rendered[-1]

    monkeypatch.setattr(
        "lib.gui.simulator.simulator_renderer.wx.CallAfter",
        lambda callback, *args: callback(*args),
    )
    renderer = PreviewRenderer(
        render,
        lambda stitch_plan: completed.set(),
        debounce_seconds=0.05,
    )

    renderer.update()
    sleep(0.01)
    renderer.update()
    sleep(0.01)
    renderer.update()

    assert completed.wait(1)
    assert rendered == [1]


def test_preview_renderer_discards_outdated_result(monkeypatch):
    first_render_started = Event()
    release_first_render = Event()
    latest_render_completed = Event()
    delivered = []
    render_count = 0

    def render():
        nonlocal render_count
        render_count += 1
        if render_count == 1:
            first_render_started.set()
            assert release_first_render.wait(1)
        return render_count

    def complete(stitch_plan):
        delivered.append(stitch_plan)
        latest_render_completed.set()

    monkeypatch.setattr(
        "lib.gui.simulator.simulator_renderer.wx.CallAfter",
        lambda callback, *args: callback(*args),
    )
    renderer = PreviewRenderer(render, complete, debounce_seconds=0.01)

    renderer.update()
    assert first_render_started.wait(1)
    renderer.update()
    release_first_render.set()

    assert latest_render_completed.wait(1)
    assert delivered == [2]


def test_cached_key_is_reused_when_saving(monkeypatch):
    cache = {}

    class FakeElement:
        def get_cache_key(self, previous_stitch, next_element):
            raise AssertionError("cache key should not be regenerated")

    monkeypatch.setattr(
        "lib.elements.element.is_cache_disabled", lambda: False
    )
    monkeypatch.setattr(
        "lib.elements.element.get_stitch_plan_cache", lambda: cache
    )

    EmbroideryElement._save_cached_stitch_groups(
        FakeElement(), [], None, None, cache_key="already-generated"
    )

    assert cache["already-generated"] == []
