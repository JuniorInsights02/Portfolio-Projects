//*
Covid 19 data exploration

Skills used- Joins, window functions, aggregate functions, CTEs, Temp tables, Creating views, Converting data types
*//

Select *
from PortfolioProject..coviddeathsinfo$
where continent is not null
order by 3,4

Select *
from PortfolioProject..['covidvaccinations-info$']
order by 3,4


--Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..coviddeathsinfo$
where continent is not null
order by 1,2


--Looking at Total cases vs Total deaths
--Shows likelihood of dying if you come in contact with covid in your country
--Modification : (the total_cases and total_deaths data type were nvarchar so had to convert them into integer)

SELECT location, date,
    CAST(total_cases AS INT) AS total_cases,
    CAST(total_deaths AS INT) AS total_deaths,
    CASE
        WHEN total_deaths = 0 THEN 0  
        ELSE (CAST(total_cases AS FLOAT) / total_deaths) * 100
	END AS DeathPercentage
FROM PortfolioProject..coviddeathsinfo$
WHERE location like '%India%'
and continent is not null
ORDER BY  1, 2


--Looking at Total cases vs Population
--shows what percentage of population got covid 

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..coviddeathsinfo$
--where location like '%India%'
order by 1,2 


--Countries with highest infection rate compared to population 

Select location, population, MAX(total_cases)as HighestInfectionCount, 
       MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..coviddeathsinfo$
Group BY location, population
order by PercentPopulationInfected desc


--Showing the countries with highest death count per population

Select location, MAX (cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..coviddeathsinfo$
where continent is not null
Group BY location
order by TotalDeathCount desc



--LET'S BREAK THINGS DOWN BY CONTINENT

--Showing continents with the highest death count per population

Select continent, MAX (cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..coviddeathsinfo$
where continent is not null
GROUP BY continent
order by TotalDeathCount desc


--GLOBAL NUMBERS
--Modification : (new_deaths data type already float, no conversion needed/ the new_cases data included 0 which might result to error)
SELECT
SUM(new_cases) AS Total_cases,
SUM(new_deaths) AS Total_Deaths,
 CASE
      WHEN SUM(new_cases) = 0 THEN 0
	  ELSE SUM(new_deaths)/SUM(new_cases)*100
	  END as DeathPercentage
 FROM PortfolioProject..coviddeathsinfo$
where continent is not null
ORDER BY  1, 2  


--Total population vs vaccinations 
--Shows percentage of population that has received atleast one Covid Vaccine
--Modification : (bigint used to convert new_vaccinations data type in order to avoid overflow issues)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as
Rollingpeoplevaccinated

FROM PortfolioProject..['covidvaccinations-info$'] vac
join PortfolioProject..coviddeathsinfo$ dea
     on dea.date = vac.date
	 and dea.location = vac.location
	 where dea.continent is not null
	 order by 2,3


--Using CTE to perform calculation on partition by in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as
Rollingpeoplevaccinated
FROM PortfolioProject..['covidvaccinations-info$'] vac 
join PortfolioProject..coviddeathsinfo$ dea 
     on dea.date = vac.date
	 and dea.location = vac.location
	 where dea.continent is not null
)
SELECT *, (Rollingpeoplevaccinated/Population)*100
FROM PopvsVac


--Using Temp tables to perform calculation on partition by in previous query

DROP TABLE if exists #PercentPopulationvaccinated
CREATE TABLE #PercentPopulationvaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_vaccinations numeric,
Rollingpeoplevaccinated numeric
)

INSERT INTO #PercentPopulationvaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as
Rollingpeoplevaccinated
FROM PortfolioProject..['covidvaccinations-info$'] vac 
join PortfolioProject..coviddeathsinfo$ dea 
     on dea.date = vac.date
	 and dea.location = vac.location
	 --where dea.continent is not null
	 --order by continent

SELECT *, (Rollingpeoplevaccinated/Population)*100
FROM #PercentPopulationvaccinated



-- Creating view to store data for later visualizations

Create view PercentPopulationvaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as
Rollingpeoplevaccinated
FROM PortfolioProject..['covidvaccinations-info$'] vac 
join PortfolioProject..coviddeathsinfo$ dea 
     on dea.date = vac.date
	 and dea.location = vac.location
	 where dea.continent is not null
	 --order by continent

select *
from PercentPopulationvaccinated






