# Authors: see git history
#
# Copyright (c) 2024 Authors
# Licensed under the GNU GPL version 3.0 or later.  See the file LICENSE for details.
from threading import Event, Lock, Thread

import wx

from ...debug.debug import debug
from ...utils.threading import ExitThread


class PreviewRenderer(Thread):
    """Render stitch plan in a background thread."""

    def __init__(self, render_stitch_plan_hook, rendering_completed_hook,
                 debounce_seconds=0.25):
        super(PreviewRenderer, self).__init__()
        self.daemon = True
        self.refresh_needed = Event()
        self.debounce_seconds = debounce_seconds

        self.render_stitch_plan_hook = render_stitch_plan_hook
        self.rendering_completed_hook = rendering_completed_hook

        # Keep track of preview requests so that a completed, but outdated,
        # render can never replace a newer preview in the simulator.
        self._request_lock = Lock()
        self._request_id = 0

        # This is read by utils.threading.check_stop_flag() to abort stitch plan
        # generation.
        self.stop = Event()

    def update(self):
        """Request to render a new stitch plan.

        self.render_stitch_plan_hook() will be called in a background thread, and then
        self.rendering_completed_hook() will be called with the resulting stitch plan.
        """

        if not self.is_alive():
            self.start()

        with self._request_lock:
            self._request_id += 1
            self.stop.set()
            self.refresh_needed.set()

    def run(self):
        while True:
            self.refresh_needed.wait()
            self.refresh_needed.clear()

            # Controls such as spin buttons and sliders can emit several
            # changes in quick succession.  Wait until they settle before
            # starting an expensive stitch-plan render.
            if self.debounce_seconds:
                while self.refresh_needed.wait(self.debounce_seconds):
                    self.refresh_needed.clear()

            # update() uses the same lock, so it cannot set the stop flag
            # between clearing it and taking the request snapshot.
            with self._request_lock:
                self.stop.clear()
                request_id = self._request_id

            try:
                debug.log("update_patches")
                self.render_stitch_plan(request_id)
            except ExitThread:
                debug.log("ExitThread caught")

    @debug.time
    def render_stitch_plan(self, request_id):
        try:
            stitch_plan = self.render_stitch_plan_hook()
            if stitch_plan:
                # rendering_completed() will be called in the main thread.
                wx.CallAfter(self._rendering_completed, request_id, stitch_plan)
        except ExitThread:
            raise
        except:  # noqa: E722
            import traceback
            debug.log(
                "unhandled exception in PreviewRenderer.render_stitch_plan(): {}".format(
                    traceback.format_exc()
                )
            )

    def _rendering_completed(self, request_id, stitch_plan):
        """Deliver a stitch plan only if no newer preview was requested."""
        with self._request_lock:
            if request_id != self._request_id:
                debug.log("discarding outdated preview")
                return

        self.rendering_completed_hook(stitch_plan)
