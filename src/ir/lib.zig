//! Ansilust IR - Intermediate Representation Library
//!
//! A unified intermediate representation for classic BBS art and modern terminal text.
//! Bridges formats like ANSI, Binary, PCBoard, XBin with UTF-8 terminal output.
//!
//! ## Architecture
//!
//! The IR uses a structure-of-arrays cell grid design for cache efficiency,
//! with separate tables for palettes, fonts, hyperlinks, and styles.
//! Supports both static documents and frame-based animations.
//!
//! ## Key Features
//!
//! - Lossless preservation of source encoding and raw bytes
//! - Grapheme cluster support for complex Unicode
//! - SAUCE metadata preservation
//! - Animation with snapshot and delta frames
//! - Hyperlink support (OSC 8)
//! - Terminal event log for unmodeled sequences
//! - Ghostty and OpenTUI integration bridges
//!
//! ## Usage Example
//!
//! ```zig
//! const ir = @import("ir");
//! const allocator = std.heap.page_allocator;
//!
//! // Create document
//! var doc = try ir.Document.init(allocator, 80, 25);
//! defer doc.deinit();
//!
//! // Set cell
//! const input = ir.CellInput{
//!     .contents = ir.CellContents{ .scalar = 'A' },
//!     .fg_color = ir.Color{ .palette = 7 },
//! };
//! try doc.setCell(0, 0, input);
//!
//! // Get cell
//! const cell = try doc.getCell(0, 0);
//! ```
//!
//! ## Modules
//!
//! - `errors`: Shared error set
//! - `encoding`: Source encoding identifiers (IANA MIBenum + vendor range)
//! - `color`: Color representation and palette management
//! - `attributes`: Text attribute bitflags and styles
//! - `sauce`: SAUCE metadata parsing and preservation
//! - `cell_grid`: Structure-of-arrays cell storage
//! - `animation`: Frame-based animation support
//! - `hyperlink`: OSC 8 hyperlink registry
//! - `event_log`: Terminal event capture
//! - `document`: Root document container
//! - `document_builder`: Safe construction facade
//! - `serialize`: Binary serialization
//! - `ghostty`: Ghostty-compatible renderer
//! - `opentui`: OpenTUI integration

const std = @import("std");

// === Core Modules ===

pub const errors = @import("errors.zig");
pub const encoding = @import("encoding.zig");
pub const color = @import("color.zig");
pub const attributes = @import("attributes.zig");
pub const sauce = @import("sauce.zig");
pub const cell_grid = @import("cell_grid.zig");
pub const animation = @import("animation.zig");
pub const hyperlink = @import("hyperlink.zig");
pub const event_log = @import("event_log.zig");
pub const document = @import("document.zig");
pub const document_builder = @import("document_builder.zig");
pub const serialize = @import("serialize.zig");
pub const ghostty = @import("ghostty.zig");
pub const opentui = @import("opentui.zig");

// === Primary API Re-exports ===

// Error handling
pub const Error = errors.Error;
pub const isRecoverable = errors.isRecoverable;
pub const Result = errors.Result;

// Encoding
pub const SourceEncoding = encoding.SourceEncoding;

// Color
pub const Color = color.Color;
pub const RGB = color.RGB;
pub const Palette = color.Palette;
pub const PaletteType = color.PaletteType;
pub const PaletteTable = color.PaletteTable;
pub const ANSI_PALETTE = color.ANSI_PALETTE;
pub const WORKBENCH_PALETTE = color.WORKBENCH_PALETTE;
pub const createVGAPalette = color.createVGAPalette;

// Attributes
pub const AttributeFlags = attributes.AttributeFlags;
pub const UnderlineStyle = attributes.UnderlineStyle;
pub const Style = attributes.Style;

// SAUCE
pub const SauceRecord = sauce.SauceRecord;
pub const SauceFlags = sauce.SauceFlags;
pub const FileType = sauce.FileType;
pub const CharacterDataType = sauce.CharacterDataType;
pub const detectSauce = sauce.detectSauce;
pub const detectComments = sauce.detectComments;

// Cell Grid
pub const CellGrid = cell_grid.CellGrid;
pub const CellContents = cell_grid.CellContents;
pub const CellView = cell_grid.CellView;
pub const CellInput = cell_grid.CellInput;
pub const CellIterator = cell_grid.CellIterator;
pub const WideFlag = cell_grid.WideFlag;
pub const GraphemePool = cell_grid.GraphemePool;

// Animation
pub const Animation = animation.Animation;
pub const Frame = animation.Frame;
pub const Snapshot = animation.Snapshot;
pub const Delta = animation.Delta;
pub const CellUpdate = animation.CellUpdate;
pub const LoopMode = animation.LoopMode;
pub const AnimationMetadata = animation.AnimationMetadata;

// Hyperlink
pub const Hyperlink = hyperlink.Hyperlink;
pub const HyperlinkTable = hyperlink.HyperlinkTable;
pub const ParamIterator = hyperlink.ParamIterator;

// Event Log
pub const EventLog = event_log.EventLog;
pub const Event = event_log.Event;
pub const EventType = event_log.EventType;
pub const EventData = event_log.EventData;
pub const PaletteUpdate = event_log.PaletteUpdate;
pub const ModeChange = event_log.ModeChange;
pub const CursorVisibility = event_log.CursorVisibility;
pub const ScreenClear = event_log.ScreenClear;
pub const TitleUpdate = event_log.TitleUpdate;
pub const RawSequence = event_log.RawSequence;
pub const CustomEvent = event_log.CustomEvent;

// Document
pub const Document = document.Document;
pub const SourceFormat = document.SourceFormat;
pub const FontInfo = document.FontInfo;
pub const BitmapFont = document.BitmapFont;

// Document Builder
pub const DocumentBuilder = document_builder.DocumentBuilder;

// Serialization
pub const serialize_document = serialize.serialize;
pub const deserialize_document = serialize.deserialize;
pub const MAGIC_HEADER = serialize.MAGIC_HEADER;
pub const FORMAT_VERSION = serialize.FORMAT_VERSION;

// Ghostty Integration
pub const toGhosttyStream = ghostty.toGhosttyStream;

// OpenTUI Integration
pub const toOptimizedBuffer = opentui.toOptimizedBuffer;

// === Tests ===

test {
    // Import all module tests
    std.testing.refAllDecls(@This());
}
