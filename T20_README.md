# T20 International Cricket — SQL Analysis Project

**Author:** Atishay Jain  
**Dataset:** T20 International Matches (2024)  
**Tools Used:** SQL (MS SQL Server / MySQL) · Power BI  

---

## Project Overview

This project performs structured SQL analysis on a T20 International cricket dataset containing match results from 2024. The goal is to extract meaningful insights such as team performance, win percentages, head-to-head records, venue dominance, and winning patterns — using progressively complex SQL queries.

---

##  Dataset Description

**Table Name:** `T20I`

| Column | Data Type | Description |
|---|---|---|
| `Team1` | VARCHAR | First team in the match |
| `Team2` | VARCHAR | Second team in the match |
| `Winner` | VARCHAR | Team that won the match |
| `Margin` | VARCHAR | Winning margin (e.g., "5 wickets", "13 runs") |
| `MatchDate` | DATE | Date of the match |
| `Ground` | VARCHAR | Venue/ground name |

### Sample Data

| Team1 | Team2 | Winner | Margin | MatchDate | Ground |
|---|---|---|---|---|---|
| West Indies | England | West Indies | 5 wickets | 2024-11-16 | Gros Islet |
| Australia | Pakistan | Australia | 13 runs | 2024-11-16 | Sydney |
| South Africa | India | India | 135 runs | 2024-11-15 | Johannesburg |
| India | Bangladesh | India | 133 runs | 2024-10-12 | Hyderabad |
| Sri Lanka | West Indies | Sri Lanka | 9 wickets | 2024-10-17 | Dambulla |

---

##  SQL Queries & Explanations

---

### Q1 — Matches Between Two Specific Teams and Their Results

```sql
WITH base AS (
    SELECT
        CASE WHEN Team1 < Team2 THEN Team1 ELSE Team2 END AS TeamA,
        CASE WHEN Team1 < Team2 THEN Team2 ELSE Team1 END AS TeamB,
        Winner
    FROM T20I
    WHERE YEAR(MatchDate) = 2024
)
SELECT
    TeamA, TeamB,
    COUNT(*) AS TotalMatches,
    SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) AS TeamA_Wins,
    SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) AS TeamB_Wins,
    CASE
        WHEN SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) >
             SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) THEN TeamA
        WHEN SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) <
             SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) THEN TeamB
        ELSE 'Tie'
    END AS DominantTeam
FROM base
GROUP BY TeamA, TeamB
ORDER BY TeamA, TeamB;
```

** Why this approach?**  
The `CASE WHEN Team1 < Team2` trick sorts teams alphabetically so (India, South Africa) and (South Africa, India) are treated as the same pair — no duplicates. The `SUM(CASE WHEN...)` counts wins per team, and the final CASE block crowns the dominant team.

---

### Q2 — Team With the Highest Number of Wins in 2024

```sql
SELECT TOP 1
    Winner,
    COUNT(*) AS TotalWins
FROM T20I
WHERE YEAR(MatchDate) = 2024
GROUP BY Winner
ORDER BY TotalWins DESC;
```

** Why this approach?**  
`GROUP BY Winner` groups rows by each team. `COUNT(*)` counts their wins. `ORDER BY DESC` + `TOP 1` picks the single best team.

---

### Q3 — Rank All Teams by Total Wins in 2024

```sql
SELECT
    Winner AS Team,
    COUNT(*) AS TotalWins,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS TeamRank
FROM T20I
WHERE YEAR(MatchDate) = 2024
GROUP BY Winner
ORDER BY TeamRank;
```

** Why this approach?**  
`RANK()` is a window function that assigns a rank without removing rows — ties get the same rank. This gives a full leaderboard, not just the top team.

---

### Q4 — Team With Highest Average Winning Margin (in Runs)

```sql
SELECT TOP 1
    Winner AS Team,
    AVG(CAST(REPLACE(Margin, ' runs', '') AS INT)) AS TeamAvgRunMargin,
    (
        SELECT AVG(CAST(REPLACE(Margin, ' runs', '') AS INT))
        FROM T20I WHERE Margin LIKE '%runs'
    ) AS OverallAvgRunMargin
FROM T20I
WHERE Margin LIKE '%runs'
GROUP BY Winner
ORDER BY TeamAvgRunMargin DESC;
```

** Why this approach?**  
`REPLACE` strips the word "runs" from the Margin string, and `CAST AS INT` makes the number usable in `AVG()`. The subquery fetches the overall average for comparison context.

---

### Q5 — Team With Highest Average Winning Margin (in Wickets)

```sql
SELECT TOP 1
    Winner AS Team,
    AVG(CAST(REPLACE(Margin, ' wickets', '') AS INT)) AS TeamAvgWicketMargin,
    (
        SELECT AVG(CAST(REPLACE(Margin, ' wickets', '') AS INT))
        FROM T20I WHERE Margin LIKE '%wickets'
    ) AS OverallAvgWicketMargin
FROM T20I
WHERE Margin LIKE '%wickets'
GROUP BY Winner
ORDER BY TeamAvgWicketMargin DESC;
```

** Why this approach?**  
Identical logic to Q4, just switching from `'runs'` to `'wickets'`. Filtering first with `LIKE` keeps only relevant rows before aggregating.

---

###  (Q6) — Matches Where Winning Margin > Average Margin

```sql
SELECT *
FROM T20I
WHERE CAST(
    REPLACE(
        REPLACE(
            REPLACE(Margin, ' runs', ''),
        ' run', ''),
    ' wickets', '')
AS INT)
>
(
    SELECT AVG(
        CAST(
            REPLACE(
                REPLACE(
                    REPLACE(Margin, ' runs', ''),
                ' run', ''),
            ' wickets', '')
        AS INT)
    )
    FROM T20I
);
```

** Why this approach?**  
Multiple `REPLACE` calls strip all margin text variants ("runs", "run", "wickets") so the number can be compared numerically. The subquery calculates the global average, and the outer query filters rows above it.

---

### (Q7) — Team With Most Wins When Chasing (Wins by Wickets)

```sql
SELECT TOP 1
    Winner AS Team,
    COUNT(*) AS ChasingWins
FROM T20I
WHERE Margin LIKE '%wickets'
GROUP BY Winner
ORDER BY ChasingWins DESC;
```

** Why this approach?**  
In cricket, winning "by wickets" means the chasing team won. Filtering on `LIKE '%wickets'` isolates those matches. `COUNT(*)` per winner then reveals the best chasing team.

---

### (Q8) — Head-to-Head Record Between Two Selected Teams

```sql
WITH matches AS (
    SELECT
        CASE WHEN Team1 < Team2 THEN Team1 ELSE Team2 END AS TeamA,
        CASE WHEN Team1 < Team2 THEN Team2 ELSE Team1 END AS TeamB,
        Winner
    FROM T20I
)
SELECT
    TeamA, TeamB,
    COUNT(*) AS TotalMatches,
    SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) AS TeamA_Wins,
    SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) AS TeamB_Wins
FROM matches
GROUP BY TeamA, TeamB
ORDER BY TeamA, TeamB;
```

** Why this approach?**  
The CTE normalises team pairs alphabetically so each rivalry appears as one row. Swap TeamA/TeamB with specific team names (e.g., `'England'` and `'Australia'`) to filter a single head-to-head.

---

### (Q9) — Month With the Highest Number of T20I Matches in 2024

```sql
SELECT TOP 1
    DATENAME(MONTH, MatchDate) AS MonthName,
    COUNT(*) AS TotalMatches
FROM T20I
WHERE YEAR(MatchDate) = 2024
GROUP BY DATENAME(MONTH, MatchDate), MONTH(MatchDate)
ORDER BY TotalMatches DESC;
```

** Why this approach?**  
`DATENAME(MONTH, ...)` returns the month name (e.g., "November"). Including `MONTH(MatchDate)` in `GROUP BY` ensures correct ordering without relying on alphabetical month names.

---

### (Q10) — Matches Played and Win Percentage Per Team

```sql
WITH all_teams AS (
    SELECT Team1 AS Team FROM T20I WHERE YEAR(MatchDate) = 2024
    UNION ALL
    SELECT Team2 AS Team FROM T20I WHERE YEAR(MatchDate) = 2024
)
SELECT
    a.Team,
    COUNT(*) AS MatchesPlayed,
    (SELECT COUNT(*) FROM T20I t WHERE t.Winner = a.Team AND YEAR(MatchDate) = 2024) AS Wins,
    ROUND(
        (SELECT COUNT(*) FROM T20I t WHERE t.Winner = a.Team AND YEAR(MatchDate) = 2024)
        * 100.0 / COUNT(*), 2
    ) AS WinPercentage
FROM all_teams a
GROUP BY a.Team
ORDER BY WinPercentage DESC;
```

** Why this approach?**  
`UNION ALL` on Team1 and Team2 means every match counts for both teams — essential since a team appears in either column. The subquery counts actual wins for each team. Win% = (Wins / MatchesPlayed) × 100.

---

### (Q11) — Most Successful Team at Each Ground

```sql
SELECT
    Ground,
    Winner AS Most_Successful_Team,
    COUNT(*) AS TotalWins
FROM T20I
GROUP BY Ground, Winner
ORDER BY TotalWins DESC;
```

**Why this approach?**  
`GROUP BY Ground, Winner` aggregates wins per team per venue. Ordering by `TotalWins DESC` surfaces the dominant team at each ground at the top of each group.

---