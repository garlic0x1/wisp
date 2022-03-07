// -*- fill-column: 64; -*-
//
// This file is part of Wisp.
//
// Wisp is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License
// as published by the Free Software Foundation, either version
// 3 of the License, or (at your option) any later version.
//
// Wisp is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General
// Public License along with Wisp. If not, see
// <https://www.gnu.org/licenses/>.
//

pub const Funs = @import("./08-fops.zig");
pub const Ctls = @import("./09-mops.zig");

pub const jets = makeOpArray(Ctls, .ctl) ++ makeOpArray(Funs, .fun);

const std = @import("std");
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const EnumArray = std.enums.EnumArray;

const wisp = @import("./ff-wisp.zig");
const Eval = @import("./04-eval.zig");
const util = @import("./00-util.zig");

const ref = wisp.ref;
const Job = Eval;
const Ptr = wisp.Ptr;
const DeclEnum = util.DeclEnum;

pub const Rest = struct { arg: u32 };

pub const FnTag = enum {
    f0x,
    f0r,
    f0,
    f1,
    f1r,
    f2,
    f3,

    pub fn from(comptime T: type) FnTag {
        return switch (T) {
            fn (*Job) anyerror!void => .f0,
            fn (*Job, u32) anyerror!void => .f1,
            fn (*Job, u32, u32) anyerror!void => .f2,
            fn (*Job, u32, u32, u32) anyerror!void => .f3,

            fn (*Job, Rest) anyerror!void => .f0r,
            fn (*Job, u32, Rest) anyerror!void => .f1r,
            fn (*Job, []u32) anyerror!void => .f0x,

            else => @compileLog("unhandled op type", T),
        };
    }

    pub fn functionType(comptime self: FnTag) type {
        return switch (self) {
            .f0 => fn (*Job) anyerror!void,
            .f1 => fn (*Job, u32) anyerror!void,
            .f2 => fn (*Job, u32, u32) anyerror!void,
            .f3 => fn (*Job, u32, u32, u32) anyerror!void,

            .f0r => fn (*Job, Rest) anyerror!void,
            .f1r => fn (*Job, u32, Rest) anyerror!void,
            .f0x => fn (*Job, []u32) anyerror!void,
        };
    }

    pub fn cast(comptime this: FnTag, x: anytype) this.functionType() {
        return @ptrCast(this.functionType(), x);
    }
};

pub const Ilk = enum { fun, ctl };

pub const Op = struct {
    txt: []const u8,
    ilk: Ilk,
    tag: FnTag,
    fun: *const anyopaque,
};

fn makeOpArray(
    comptime S: type,
    comptime ilk: Ilk,
) [std.meta.declarations(S).len]Op {
    const decls = std.meta.declarations(S);
    var ops: [decls.len]Op = undefined;

    var i = 0;
    inline for (decls) |x| {
        if (x.is_pub) {
            const f = @field(S, x.name);
            ops[i] = .{
                .txt = x.name,
                .ilk = ilk,
                .tag = FnTag.from(@TypeOf(f)),
                .fun = f,
            };
            i += 1;
        }
    }

    return ops;
}

test "ops" {
    try expectEqual(
        @ptrCast(*const anyopaque, Ctls.QUOTE),
        jets[0].fun,
    );
}

pub fn load(ctx: *wisp.Ctx) !void {
    inline for (jets) |jet, i| {
        var sym = try ctx.intern(jet.txt, ctx.base);
        ctx.col(.sym, .fun)[ref(sym)] = wisp.Imm.make(.jet, i).word();
    }
}
