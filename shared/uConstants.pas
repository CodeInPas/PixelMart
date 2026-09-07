unit uConstants;

{$mode objfpc}{$H+}

interface

uses
  Graphics; // Diperlukan untuk konstanta TColor

const
  // =========================================================================
  // 1. ENGINE & DISPLAY SETTINGS
  // =========================================================================
  TARGET_FPS       = 30;
  MS_PER_UPDATE    = 1000 div TARGET_FPS; // ~33ms per frame tick

  // Tile-Based System
  TILE_SIZE        = 32;                  // 32x32 pixels per blok grid
  GRID_COLS        = 18;                  // Lebar area simulasi (kolom)
  GRID_ROWS        = 18;                  // Tinggi area simulasi (baris)

  // Kalkulasi Viewport otomatis oleh Kompiler
  VIEWPORT_WIDTH   = TILE_SIZE * GRID_COLS; // 800 px
  VIEWPORT_HEIGHT  = TILE_SIZE * GRID_ROWS; // 576 px

  // =========================================================================
  // 2. GAME LOOP STATES (Fase Harian)
  // =========================================================================
  STATE_PREP       = 0; // Pagi: Game Paused, Atur stok & harga
  STATE_OPEN       = 1; // Siang: Real-time, Pelanggan berbelanja
  STATE_SUMMARY    = 2; // Malam: Game Paused, Rekap laba/rugi
  STATE_GAMEOVER   = 3; // Loss Condition: Bangkrut

  // =========================================================================
  // 3. ECONOMY & SIMULATION BALANCING
  // =========================================================================
  STARTING_CAPITAL = 500000;              // Saldo awal Rp 500.000
  MAX_RACKS        = 20;                  // Limit objek rak dalam array
  MAX_NPC_ACTIVE   = 15;                  // Batas maksimum NPC di layar sekaligus

  DAY_DURATION_SEC = 120;                 // 1 hari operasional = 2 menit (Real Time)
  PRICE_TOLERANCE  = 1.3;                 // Batas margin maksimal (30% dari modal) sblm NPC menolak beli

  // =========================================================================
  // 4. ENTITY DIRECTIONS (Untuk Sprite / Pathfinding)
  // =========================================================================
  DIR_UP           = 0;
  DIR_RIGHT        = 1;
  DIR_DOWN         = 2;
  DIR_LEFT         = 3;
  DIR_IDLE         = 4;

  // =========================================================================
  // 5. COLOR PALETTES (LCL Graphics)
  // Format TColor FPC = $00BBGGRR (Blue-Green-Red)
  // =========================================================================
  COLOR_BG_FLOOR   = $00E0E0E0;           // Abu-abu terang (Lantai)
  COLOR_WALL       = $004A4A4A;           // Abu-abu gelap (Tembok)
  COLOR_TEXT_MONEY = $004CAF50;           // Hijau (Floating text laba)
  COLOR_TEXT_WARN  = $00F44336;           // Merah (Rugi / Peringatan)
  COLOR_UI_PANEL   = $00282828;           // Gelap (Background UI Kanan)

implementation

// Tidak ada logic runtime, unit murni untuk kamus konstanta global.

end.

