
-- Let's display likelihood/percentaage of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, 
       (CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeath
ORDER BY 1, 2;


SELECT Location, date, total_cases, total_deaths, 
       (CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeath
WHERE Location LIKE '%states%' 
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (CONVERT(FLOAT, total_cases) / CONVERT(FLOAT, population))*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeath
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeath
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeath
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeath
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- To achieve this, we have to join combine two tables together namely dbo.CovidDeath and dbo.CovidVacination



SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
       (SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / CAST(dea.population AS FLOAT)) * 100 AS VaccinationPercentage
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVacination vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject.dbo.CovidDeath dea
Join PortfolioProject.dbo.CovidVacination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC,
    VaccinationPercentage NUMERIC -- Changed the column name
);

INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated, VaccinationPercentage)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
       (SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) / CAST(dea.population AS FLOAT)) * 100 AS [VaccinationPercentage] -- Modified column name
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVacination vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVacination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



select * 
From PercentPopulationVaccinated
