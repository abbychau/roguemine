const { getDatabase } = require('../database');

/**
 * Highscore model for database operations
 */
class HighscoreModel {
  
  /**
   * Save a new highscore
   */
  static async saveHighscore(encodedData, playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp, ipAddress) {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = `
        INSERT INTO highscores (
          encoded_data, player_name, score, time_taken, 
          tiles_revealed, chords_performed, timestamp, ip_address
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        encodedData, playerName, score, timeTaken,
        tilesRevealed, chordsPerformed, timestamp, ipAddress
      ];
      
      db.run(sql, params, function(err) {
        if (err) {
          if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
            reject(new Error('Duplicate highscore data'));
          } else {
            reject(err);
          }
        } else {
          resolve({
            id: this.lastID,
            rank: null // Will be calculated separately
          });
        }
      });
    });
  }
  
  /**
   * Get top highscores
   */
  static async getTopHighscores(limit = 10) {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = `
        SELECT 
          player_name, score, time_taken, tiles_revealed, 
          chords_performed, created_at,
          ROW_NUMBER() OVER (ORDER BY score DESC, time_taken ASC) as rank
        FROM highscores 
        ORDER BY score DESC, time_taken ASC 
        LIMIT ?
      `;
      
      db.all(sql, [limit], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }
  
  /**
   * Get rank for a specific score
   */
  static async getRankForScore(score, timeTaken) {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = `
        SELECT COUNT(*) + 1 as rank
        FROM highscores 
        WHERE score > ? OR (score = ? AND time_taken < ?)
      `;
      
      db.get(sql, [score, score, timeTaken], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row.rank);
        }
      });
    });
  }
  
  /**
   * Get total number of highscores
   */
  static async getTotalCount() {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = 'SELECT COUNT(*) as count FROM highscores';
      
      db.get(sql, [], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row.count);
        }
      });
    });
  }
  
  /**
   * Check if score qualifies for top rankings
   */
  static async isTopScore(score, timeTaken, topCount = 10) {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = `
        SELECT COUNT(*) as count
        FROM highscores 
        WHERE score > ? OR (score = ? AND time_taken < ?)
      `;
      
      db.get(sql, [score, score, timeTaken], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row.count < topCount);
        }
      });
    });
  }
  
  /**
   * Clean up old entries (keep only top N)
   */
  static async cleanupOldEntries(keepCount = 100) {
    return new Promise((resolve, reject) => {
      const db = getDatabase();
      
      const sql = `
        DELETE FROM highscores 
        WHERE id NOT IN (
          SELECT id FROM highscores 
          ORDER BY score DESC, time_taken ASC 
          LIMIT ?
        )
      `;
      
      db.run(sql, [keepCount], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.changes);
        }
      });
    });
  }
}

module.exports = HighscoreModel;
