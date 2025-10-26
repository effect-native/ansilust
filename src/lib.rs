//! Ansilust IR - Intermediate Representation for text art
//! 
//! This library implements a unified IR for classic BBS art (ANSI, Binary, PCBoard, XBin)
//! and modern terminal output (UTF8ANSI). It follows the Cell Grid IR approach (Approach 1)
//! from IR-RESEARCH.md.

pub mod ir;

pub use ir::*;
