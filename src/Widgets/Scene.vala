/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace TrimDown.Widgets {
    public class Scene : Gtk.ListBoxRow {
        public signal void reorder_request (int from, int to);

        public Objects.Scene scene { get; private set; }

        public new string name { get { return scene.name; } }
        public int order { get { return scene.order; } }

        Enums.ItemStyle item_style;

        Gtk.Label label;
        Gtk.Button action_button;
        Gtk.Image redo_img;
        Gtk.Image trash_img;

        const Gtk.TargetEntry[] targetentries = {{ "STRING", 0, 0 }};

        public Scene (Objects.Scene scene, Enums.ItemStyle item_style = Enums.ItemStyle.DEFAULT) {
            this.scene = scene;
            this.scene.bin_location_changed.connect (
                (bin) => {
                    if (bin) {
                        action_button.set_image (redo_img);
                    } else {
                        action_button.set_image (trash_img);
                    }
                });
            this.scene.parent.bin_location_changed.connect (
                (bin) => {
                    action_button.visible = bin;
                });
            this.item_style = item_style;

            build_ui ();
        }

        private void build_ui () {
            label = new Gtk.Label (scene.name);
            label.expand = true;
            label.xalign = 0;
            label.margin = 12;

            var event_box = new Gtk.EventBox ();

// DRAG DROP
            Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, targetentries, Gdk.DragAction.MOVE);
            event_box.drag_data_get.connect (on_drag_data_get);

            Gtk.drag_dest_set (event_box, Gtk.DestDefaults.ALL, targetentries, Gdk.DragAction.MOVE);
            event_box.drag_leave.connect (
                (context, time) => {
                    label.margin_top = 12;
                    this.get_style_context ().remove_class ("chapter-drag-begin");
                });
            event_box.drag_motion.connect (
                (context, x, y, time) => {
                    label.margin_top = 11;
                    Gtk.drag_unhighlight (event_box);
                    this.get_style_context ().add_class ("chapter-drag-begin");
                    return false;
                });
            event_box.drag_data_received.connect (
                (drag_context, x, y, data, info, time) => {
                    on_drag_data_received (data.get_text ());
                });

            var content = new Gtk.Grid ();

            redo_img = new Gtk.Image.from_icon_name ("edit-redo-symbolic", Gtk.IconSize.BUTTON);
            redo_img.tooltip_text = _ ("Restore from Bin");
            trash_img = new Gtk.Image.from_icon_name ("user-trash-symbolic", Gtk.IconSize.BUTTON);
            trash_img.tooltip_text = _ ("Move into Bin");

            action_button = new Gtk.Button ();
            action_button.valign = Gtk.Align.CENTER;

            if (scene.bin) {
                action_button.set_image (redo_img);
            } else {
                action_button.set_image (trash_img);
            }
            action_button.get_style_context ().add_class ("flat");
            action_button.can_focus = false;
            action_button.halign = Gtk.Align.END;
            action_button.opacity = 0;

            action_button.clicked.connect (
                () => {
                    if (scene.bin) {
                        scene.restore_from_bin ();
                    } else {
                        scene.move_into_bin ();
                    }
                });
            action_button.enter_notify_event.connect (
                (event) => {
                    action_button.opacity = 1;
                    return false;
                });

            event_box.enter_notify_event.connect (
                (event) => {
                    action_button.opacity = 0.5;
                    return false;
                });
            event_box.leave_notify_event.connect (
                (event) => {
                    action_button.opacity = 0;
                    return false;
                });
            content.attach (action_button, 1, 0);

            if (item_style == Enums.ItemStyle.BIN) {
                label.margin = 6;
            }

            content.margin_right = 0;
            content.attach (label, 0, 0);
            event_box.add (content);

            this.add (event_box);
            this.show_all ();

            if (scene.parent.bin) {
                action_button.hide ();
            }
        }

        private void on_drag_data_get (Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
            this.activate ();
            selection_data.set_text ("Scene:%d".printf (scene.order), -1);
        }

        private void on_drag_data_received (string received) {
            Regex reg_scene_order;
            try {
                reg_scene_order = new Regex ("(?<=Scene:)\\d*");
            } catch (Error err) {
                return;
            }

            int source_scene_order = scene.order;

            MatchInfo match;

            if (reg_scene_order.match (received, 0, out match)) {
                source_scene_order = int.parse (match.fetch (0));
            }

            if (source_scene_order != scene.order) {
                reorder_request (source_scene_order, scene.order);
            }
        }
    }
}