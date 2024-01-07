-- 1. How many olympics games have been held?

SELECT 
    COUNT(DISTINCT games) AS games_count
FROM
    athlete_events;

-- 2. List down all Olympics games held so far.

SELECT DISTINCT
    year, season, city
FROM
    athlete_events
ORDER BY 1 ASC;

-- 3. Mention the total no of nations who participated in each olympics game?

select * from athlete_events limit 5;

SELECT 
    Games, COUNT(DISTINCT team) AS nations
FROM
    athlete_events
GROUP BY 1;

-- 4. Which year saw the highest and lowest no of countries participating in olympics?
-- Highest
SELECT Year, Season, COUNT(DISTINCT NOC) AS Total_Nations 
FROM athlete_events 
GROUP BY Year, Season 
ORDER BY Total_Nations DESC 
LIMIT 1;

-- Lowest
SELECT Year, Season, COUNT(DISTINCT NOC) AS Total_Nations 
FROM athlete_events 
GROUP BY Year, Season 
ORDER BY Total_Nations 
LIMIT 1;


-- 5. Which nation has participated in all of the olympic games?
SELECT NOC 
FROM (
  SELECT NOC, COUNT(DISTINCT Year) AS Total_Participations 
  FROM athlete_events 
  GROUP BY NOC
) AS Participation_Count 
WHERE Total_Participations = (SELECT COUNT(DISTINCT Year) FROM athlete_events);

-- 6. Identify the sport which was played in all summer olympics.
SELECT Sport 
FROM (
  SELECT Sport, COUNT(DISTINCT Year) AS Total_Participations 
  FROM athlete_events 
  WHERE Season = 'Summer' 
  GROUP BY Sport
) AS Sport_Participation 
WHERE Total_Participations = (SELECT COUNT(DISTINCT Year) FROM athlete_events WHERE Season = 'Summer');

-- 7. Which Sports were just played only once in the olympics?
SELECT Sport 
FROM athlete_events 
GROUP BY Sport 
HAVING COUNT(DISTINCT Year) = 1;

-- 8. Fetch the total no of sports played in each olympic games.
SELECT Year, Season, COUNT(DISTINCT Sport) AS Total_Sports 
FROM athlete_events 
GROUP BY Year, Season;

-- 9. Fetch details of the oldest athletes to win a gold medal.
SELECT Name, Age, Year, Sport, Event 
FROM athlete_events 
WHERE Age = (SELECT MAX(Age) FROM athlete_events WHERE Medal = 'Gold') 
  AND Medal = 'Gold';

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
SELECT (SELECT COUNT(DISTINCT ID) FROM athlete_events WHERE Sex = 'M') / 
       (SELECT COUNT(DISTINCT ID) FROM athlete_events WHERE Sex = 'F') AS Male_Female_Ratio;

-- 11. Fetch the top 5 athletes who have won the most gold medals.
SELECT Name, COUNT(Medal) AS Total_Gold_Medals 
FROM athlete_events 
WHERE Medal = 'Gold' 
GROUP BY Name 
ORDER BY Total_Gold_Medals DESC 
LIMIT 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT NOC, COUNT(Medal) AS Total_Medals 
FROM athlete_events 
WHERE Medal IS NOT NULL 
GROUP BY NOC 
ORDER BY Total_Medals DESC 
LIMIT 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
SELECT NOC, COUNT(Medal) AS Total_Medals 
FROM athlete_events 
WHERE Medal IS NOT NULL 
GROUP BY NOC 
ORDER BY Total_Medals DESC 
LIMIT 5;

-- 14. List down total gold, silver and broze medals won by each country.
SELECT NOC, 
       SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
       SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
       SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events 
GROUP BY NOC;

-- 15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT Year, Season, NOC, 
       SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
       SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
       SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events 
GROUP BY Year, Season, NOC;

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH GoldMedals AS (
    SELECT Year, ae.NOC, COUNT(ae.Medal) AS Gold_Count
    FROM athlete_events ae
    WHERE Medal = 'Gold'
    GROUP BY Year, ae.NOC
),
SilverMedals AS (
    SELECT Year, ae.NOC, COUNT(ae.Medal) AS Silver_Count
    FROM athlete_events ae
    WHERE Medal = 'Silver'
    GROUP BY Year, ae.NOC
),
BronzeMedals AS (
    SELECT Year, ae.NOC, COUNT(ae.Medal) AS Bronze_Count
    FROM athlete_events ae
    WHERE Medal = 'Bronze'
    GROUP BY Year, ae.NOC
),
MaxGold AS (
    SELECT Year, MAX(Gold_Count) AS MaxGold
    FROM GoldMedals
    GROUP BY Year
),
MaxSilver AS (
    SELECT Year, MAX(Silver_Count) AS MaxSilver
    FROM SilverMedals
    GROUP BY Year
),
MaxBronze AS (
    SELECT Year, MAX(Bronze_Count) AS MaxBronze
    FROM BronzeMedals
    GROUP BY Year
)
SELECT 
    G.Year, 
    (SELECT CONCAT(nr.region, ' - ', gm.Gold_Count) FROM GoldMedals gm JOIN noc_regions nr ON gm.NOC = nr.NOC WHERE Year = G.Year AND Gold_Count = G.MaxGold ORDER BY gm.NOC LIMIT 1) AS Gold_Winner,
    (SELECT CONCAT(nr.region, ' - ', sm.Silver_Count) FROM SilverMedals sm JOIN noc_regions nr ON sm.NOC = nr.NOC WHERE Year = S.Year AND Silver_Count = S.MaxSilver ORDER BY sm.NOC LIMIT 1) AS Silver_Winner,
    (SELECT CONCAT(nr.region, ' - ', bm.Bronze_Count) FROM BronzeMedals bm JOIN noc_regions nr ON bm.NOC = nr.NOC WHERE Year = B.Year AND Bronze_Count = B.MaxBronze ORDER BY bm.NOC LIMIT 1) AS Bronze_Winner
FROM MaxGold G
JOIN MaxSilver S ON G.Year = S.Year
JOIN MaxBronze B ON G.Year = B.Year
ORDER BY 1 ASC;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH MedalCounts AS (
    SELECT Year, ae.NOC, 
           SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Count,
           SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Count,
           SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Count,
           COUNT(Medal) AS Total_Medals
    FROM athlete_events ae
    GROUP BY Year, ae.NOC
),
MaxMedals AS (
    SELECT Year,
           MAX(Gold_Count) AS MaxGold,
           MAX(Silver_Count) AS MaxSilver,
           MAX(Bronze_Count) AS MaxBronze,
           MAX(Total_Medals) AS MaxTotal
    FROM MedalCounts
    GROUP BY Year
)
SELECT 
    M.Year, 
    (SELECT CONCAT(nr.region, ' - ', mc.Gold_Count) FROM MedalCounts mc JOIN noc_regions nr ON mc.NOC = nr.NOC WHERE Year = M.Year AND Gold_Count = M.MaxGold ORDER BY mc.NOC LIMIT 1) AS Most_Gold,
    (SELECT CONCAT(nr.region, ' - ', mc.Silver_Count) FROM MedalCounts mc JOIN noc_regions nr ON mc.NOC = nr.NOC WHERE Year = M.Year AND Silver_Count = M.MaxSilver ORDER BY mc.NOC LIMIT 1) AS Most_Silver,
    (SELECT CONCAT(nr.region, ' - ', mc.Bronze_Count) FROM MedalCounts mc JOIN noc_regions nr ON mc.NOC = nr.NOC WHERE Year = M.Year AND Bronze_Count = M.MaxBronze ORDER BY mc.NOC LIMIT 1) AS Most_Bronze,
    (SELECT CONCAT(nr.region, ' - ', mc.Total_Medals) FROM MedalCounts mc JOIN noc_regions nr ON mc.NOC = nr.NOC WHERE Year = M.Year AND Total_Medals = M.MaxTotal ORDER BY mc.NOC LIMIT 1) AS Most_Medals
FROM MaxMedals M;


-- 18. Which countries have never won gold medal but have won silver/bronze medals?
SELECT NOC 
FROM athlete_events 
WHERE Medal IN ('Silver', 'Bronze')
  AND NOC NOT IN (SELECT NOC FROM athlete_events
  WHERE Medal = 'Gold')
GROUP BY NOC;

-- 19. In which Sport/event, India has won highest medals.
SELECT Sport, COUNT(Medal) AS Total_Medals 
FROM athlete_events 
WHERE Team = 'India' AND Medal IS NOT NULL 
GROUP BY Sport 
ORDER BY Total_Medals DESC 
LIMIT 1;

-- 20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
SELECT Year, Season, COUNT(Medal) AS Total_Medals 
FROM athlete_events 
WHERE Team = 'India' AND Sport = 'Hockey' AND Medal IS NOT NULL 
GROUP BY Year, Season;
