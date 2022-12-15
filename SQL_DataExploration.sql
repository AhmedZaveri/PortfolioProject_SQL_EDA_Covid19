 SELECT *
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent is not null
 order by location, date

 SELECT *
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent is null
 order by location, date

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY location, date

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying due to covid in Germany
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'Germany'
ORDER BY location, date

--Looking at Total Cases vs Population
--Shows what percentage of population contracted Covid
 SELECT Location, date, total_cases, population, (total_cases/population)*100 AS Percent_Population_Infected
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE Location = 'Germany'
 ORDER BY location, date
 
 --Looking at Countries with highest infection rate in comparison to population
 SELECT Location, Population, date, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population)*100) AS Percent_Population_Infected
 FROM PortfolioProject.dbo.CovidDeaths
 --WHERE population > 1000000
 GROUP BY Location, Population, date
 ORDER BY Percent_Population_Infected DESC

 --Showing Countries with Highest Death Count with respect to Population
 SELECT Location, MAX(cast(total_deaths AS BIGINT)) AS Total_Death_Count
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY Location
 ORDER BY Total_Death_Count DESC

 --BREAKING THINGS DOWN ON THE BASIS OF CONTINENT
 --Showing the continents with the highest death counts
 SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS Total_Death_Count
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent IS NULL
 AND location IN ('Asia','Africa','North America','South America','Europe','Oceania')
 GROUP BY location
 ORDER BY Total_Death_Count DESC

 --Global Numbers
 SELECT date, SUM(new_cases) AS TotalCasesGlobal, SUM(CAST(new_deaths AS BIGINT)) AS TotalDeathsGlobal, 
 (SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases))*100 AS DeathPercentage
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY date
 --OR using World metrics directly
 SELECT date, new_cases, new_deaths, (CAST(new_deaths AS BIGINT)/new_cases)*100 AS DeathPercentage
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE location = 'world' AND cast(new_deaths AS BIGINT) <> 0
 ORDER BY date

 --Overall Death Percentage Globally
 SELECT SUM(new_cases) AS TotalCasesGlobalCumulative, SUM(CAST(new_deaths AS BIGINT)) AS TotalDeathsGlobalCumulative, 
 (SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases))*100 AS DeathPercentage
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE continent IS NOT NULL
 --OR using World Metrics directly
 SELECT SUM(new_cases) AS TotalCasesGlobalCumulative, SUM(CAST(new_deaths AS BIGINT)) AS TotalDeathsGlobalCumulative, 
 SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases)*100 AS DeathPercentage
 FROM PortfolioProject.dbo.CovidDeaths
 WHERE location = 'world'
 GROUP BY Location

--Looking for Total Population Vs Vaccinations
SELECT death.continent, death.location, death.date, death.population, vacc.people_fully_vaccinated
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date

--Total People getting Vaccinated Cumulatively with every passing day
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(BIGINT,vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS PeopleVaccinatedCumulative
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date

--Using CTE to create table to use PeopleVaccinatedCumulative
WITH PopvsVacc (Continent, Location, Date, Population, New_vaccinations, PeopleVaccinatedCumulative) AS
(SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(BIGINT,vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS PeopleVaccinatedCumulative
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL)
SELECT *, (PeopleVaccinatedCumulative/Population)*100
FROM PopvsVacc

--OR Use Temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), 
 Location nvarchar(255), 
 Date datetime, 
 Population numeric, 
 New_vaccinations numeric, 
 PeopleVaccinatedCumulative numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(BIGINT,vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS PeopleVaccinatedCumulative
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL

SELECT *, (PeopleVaccinatedCumulative/Population)*100 AS PercentagePopVacc
FROM #PercentPopulationVaccinated

--OR Use People fully Vaccinated Column directly from Table to find % of population vaccinated
SELECT death.location, MAX(death.population) AS Population, MAX((CONVERT(BIGINT, vacc.people_fully_vaccinated))) AS TotalFullyVaccinated,
(MAX(CONVERT(BIGINT, vacc.people_fully_vaccinated))/MAX(death.population))*100 AS PercentagePopVacc
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
GROUP BY death.location
ORDER BY PercentagePopVacc DESC

--Creating view to store data for later visualisations\
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(BIGINT,vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS PeopleVaccinatedCumulative
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL

SELECT *
From PercentPopulationVaccinated