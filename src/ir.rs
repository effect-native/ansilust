//! Core IR data structures for ansilust
//! 
//! Implements the Cell Grid IR (Approach 1) from IR-RESEARCH.md

use bitflags::bitflags;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Main intermediate representation structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnsilustIR {
    /// IR format version
    pub version: String,
    
    /// Canvas dimensions
    pub width: u32,
    pub height: u32,
    
    /// Flattened cell grid (width × height)
    pub cells: Vec<Cell>,
    
    /// Reference-counted style table (Ghostty pattern)
    pub style_table: Vec<Style>,
    
    /// Multi-codepoint grapheme storage
    pub grapheme_map: HashMap<u32, Vec<u32>>,
    
    /// Resources
    pub palette: PaletteType,
    pub font: FontInfo,
    
    /// Metadata
    pub sauce: Option<SauceRecord>,
    pub source_format: SourceFormat,
    
    /// Rendering hints (from SAUCE or command-line)
    pub ice_colors: bool,
    pub letter_spacing: u8,  // 8 or 9
    pub aspect_ratio: Option<f32>,  // 1.35 for DOS
    
    /// Animation frames (optional)
    pub frames: Option<Vec<Frame>>,
}

/// Individual cell in the grid
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Cell {
    /// Unicode codepoint or CP437 character code
    pub char: u32,
    
    /// Index into style_table
    pub style_id: u16,
    
    /// Cell flags (wide char, wrap, etc.)
    pub flags: CellFlags,
}

bitflags! {
    /// Cell flags (inspired by Ghostty)
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
    pub struct CellFlags: u8 {
        /// Double-width character (CJK, emoji)
        const WIDE_CHAR      = 0b0000_0001;
        /// Second half of wide char
        const SPACER_TAIL    = 0b0000_0010;
        /// Wrapped wide char marker
        const SPACER_HEAD    = 0b0000_0100;
        /// Line soft-wraps to next row
        const SOFT_WRAP      = 0b0000_1000;
        /// Write-protected cell
        const PROTECTED      = 0b0001_0000;
    }
}

/// Style information (reference-counted)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Style {
    pub fg: Color,
    pub bg: Color,
    /// Separate underline color (can differ from fg!)
    pub underline_color: Option<Color>,
    pub attributes: Attributes,
    /// Optional hyperlink reference
    pub hyperlink: Option<u32>,
}

/// Color representation (supports classic and modern)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Color {
    /// Terminal default (not black!)
    None,
    /// Palette index (0-255)
    Palette(u8),
    /// 24-bit true color
    RGB(u8, u8, u8),
}

bitflags! {
    /// Text attributes (Ghostty-inspired with BBS extensions)
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
    pub struct Attributes: u16 {
        const BOLD              = 0b0000_0000_0000_0001;
        const FAINT             = 0b0000_0000_0000_0010;
        const ITALIC            = 0b0000_0000_0000_0100;
        const UNDERLINE         = 0b0000_0000_0000_1000;
        const UNDERLINE_DOUBLE  = 0b0000_0000_0001_0000;
        const UNDERLINE_CURLY   = 0b0000_0000_0010_0000;
        const BLINK             = 0b0000_0000_0100_0000;
        const REVERSE           = 0b0000_0000_1000_0000;
        const INVISIBLE         = 0b0000_0001_0000_0000;
        const STRIKETHROUGH     = 0b0000_0010_0000_0000;
        const OVERLINE          = 0b0000_0100_0000_0000;
    }
}

/// Palette type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PaletteType {
    /// Standard ANSI palette
    ANSI,
    /// Standard VGA palette
    VGA,
    /// Amiga Workbench palette
    Workbench,
    /// Custom palette (16 or 256 colors)
    Custom(Palette),
}

/// Custom palette definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Palette {
    pub colors: Vec<RGB>,
}

/// RGB color
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct RGB {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

/// Font information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FontInfo {
    /// Font ID (e.g., "cp437", "topaz")
    pub id: Option<String>,
    /// Character width (8 or 9)
    pub width: u8,
    /// Character height (8, 16, 32)
    pub height: u8,
    /// Embedded bitmap font data (for XBin, ArtWorx)
    pub embedded: Option<BitmapFont>,
}

/// Bitmap font data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BitmapFont {
    pub width: u8,
    pub height: u8,
    /// 256 or 512 characters
    pub char_count: u16,
    /// Bitmap data (width * height * char_count bytes)
    pub data: Vec<u8>,
}

/// SAUCE metadata record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SauceRecord {
    pub title: String,
    pub author: String,
    pub group: String,
    pub date: String,  // CCYYMMDD
    pub columns: u16,  // tinfo1
    pub rows: u16,     // tinfo2
    pub flags: SauceFlags,
    pub font_name: String,
    pub comments: Vec<String>,
}

bitflags! {
    /// SAUCE flags byte
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
    pub struct SauceFlags: u8 {
        const ICE_COLORS         = 0b0000_0001;
        const LETTER_SPACING_9BIT = 0b0000_0100;
        const ASPECT_RATIO       = 0b0000_1000;
    }
}

/// Source format type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SourceFormat {
    ANSI,
    Binary,
    PCBoard,
    XBin,
    Tundra,
    ArtWorx,
    IceDraw,
    UTF8ANSI,
}

/// Animation frame
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Frame {
    /// Timestamp in milliseconds
    pub timestamp_ms: u32,
    /// Operations to apply
    pub operations: Vec<Operation>,
}

/// Frame operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Operation {
    SetCell { x: u32, y: u32, cell: Cell },
    FillRect { x: u32, y: u32, w: u32, h: u32, cell: Cell },
    ScrollRect { x: u32, y: u32, w: u32, h: u32, dx: i32, dy: i32 },
    SetPalette { palette: PaletteType },
}

impl AnsilustIR {
    /// Create a new IR with given dimensions
    pub fn new(width: u32, height: u32) -> Self {
        let size = (width * height) as usize;
        let default_cell = Cell {
            char: b' ' as u32,
            style_id: 0,
            flags: CellFlags::empty(),
        };
        
        let default_style = Style {
            fg: Color::Palette(7),  // White
            bg: Color::Palette(0),  // Black
            underline_color: None,
            attributes: Attributes::empty(),
            hyperlink: None,
        };
        
        Self {
            version: "0.1.0".to_string(),
            width,
            height,
            cells: vec![default_cell; size],
            style_table: vec![default_style],
            grapheme_map: HashMap::new(),
            palette: PaletteType::ANSI,
            font: FontInfo {
                id: Some("cp437".to_string()),
                width: 8,
                height: 16,
                embedded: None,
            },
            sauce: None,
            source_format: SourceFormat::ANSI,
            ice_colors: false,
            letter_spacing: 8,
            aspect_ratio: None,
            frames: None,
        }
    }
    
    /// Get cell at (x, y)
    pub fn get_cell(&self, x: u32, y: u32) -> Option<&Cell> {
        if x >= self.width || y >= self.height {
            return None;
        }
        let index = (y * self.width + x) as usize;
        self.cells.get(index)
    }
    
    /// Set cell at (x, y)
    pub fn set_cell(&mut self, x: u32, y: u32, cell: Cell) -> bool {
        if x >= self.width || y >= self.height {
            return false;
        }
        let index = (y * self.width + x) as usize;
        if let Some(c) = self.cells.get_mut(index) {
            *c = cell;
            true
        } else {
            false
        }
    }
    
    /// Get style by ID
    pub fn get_style(&self, style_id: u16) -> Option<&Style> {
        self.style_table.get(style_id as usize)
    }
    
    /// Add style to table (returns style_id)
    pub fn add_style(&mut self, style: Style) -> u16 {
        // Check if style already exists (for reference counting)
        for (id, existing) in self.style_table.iter().enumerate() {
            if existing == &style {
                return id as u16;
            }
        }
        
        // Add new style
        self.style_table.push(style);
        (self.style_table.len() - 1) as u16
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_create_ir() {
        let ir = AnsilustIR::new(80, 25);
        assert_eq!(ir.width, 80);
        assert_eq!(ir.height, 25);
        assert_eq!(ir.cells.len(), 80 * 25);
    }
    
    #[test]
    fn test_cell_access() {
        let mut ir = AnsilustIR::new(80, 25);
        
        // Set cell
        let cell = Cell {
            char: b'A' as u32,
            style_id: 0,
            flags: CellFlags::empty(),
        };
        assert!(ir.set_cell(0, 0, cell));
        
        // Get cell
        let retrieved = ir.get_cell(0, 0).unwrap();
        assert_eq!(retrieved.char, b'A' as u32);
        
        // Out of bounds
        assert!(ir.get_cell(100, 100).is_none());
        assert!(!ir.set_cell(100, 100, cell));
    }
    
    #[test]
    fn test_style_table() {
        let mut ir = AnsilustIR::new(80, 25);
        
        let style = Style {
            fg: Color::RGB(255, 0, 0),
            bg: Color::None,
            underline_color: None,
            attributes: Attributes::BOLD,
            hyperlink: None,
        };
        
        let id1 = ir.add_style(style.clone());
        let id2 = ir.add_style(style.clone());  // Should reuse
        
        assert_eq!(id1, id2);  // Reference counting
        assert_eq!(ir.style_table.len(), 2);  // Default + new style
    }
    
    #[test]
    fn test_cell_flags() {
        let flags = CellFlags::WIDE_CHAR | CellFlags::SOFT_WRAP;
        assert!(flags.contains(CellFlags::WIDE_CHAR));
        assert!(flags.contains(CellFlags::SOFT_WRAP));
        assert!(!flags.contains(CellFlags::SPACER_TAIL));
    }
}
