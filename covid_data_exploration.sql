SELECT * FROM covid_deaths ORDER BY 3,4;

-- Data to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE location = 'Pakistan'
ORDER BY 1,2;

--total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percetage_of_deaths 
FROM covid_deaths
WHERE location = 'Pakistan'
ORDER BY 1,2;

--Total cases vs Population
SELECT location, date, total_cases, population, (total_deaths/population)*100 AS total_percentage_of_cases 
FROM covid_deaths
WHERE location = 'Pakistan'
ORDER BY 1,2;

--highest infection rates
SELECT location, population, MAX(total_cases) AS max_total_cases, MAX((total_cases/population))*100 AS percentage_of_population_infected 
FROM covid_deaths
GROUP BY location, population
ORDER BY percentage_of_population_infected desc;

--Highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc;

--according to continent
SELECT continent, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc;

--according to location
select location, max(total_deaths) as total_death_count
from covid_deaths
where continent is null
group by location
order by total_death_count;

-- global numbers
select
	sum(new_cases) as sum_of_new_cases,
	sum(new_deaths) as sum_of_new_deaths,
    (cast(sum(new_deaths) as decimal) / cast(sum(new_cases) as decimal)) * 100 as percentage_of_deaths
from
	covid_deaths
where
	continent is not null;

select *
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date;

--looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
where new_vaccinations is not null
order by 2,3;

--total population and sum of new vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations,
((sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date))/population)*100 as percentage_of_rcv
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3;

--using CTE
with PopulationvsVaccination(continent, location, date, population, new_vaccinations, rolling_count_vaccinations)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

select *, (rolling_count_vaccinations/population)*100 as percentage_of_RCV
from PopulationvsVaccination;

--using temp table
drop table if exists percent_population_vaccinated;

create table percent_population_vaccinated
(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
);

insert into percent_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinations
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date;
--where dea.continent is not null;

select *, (rolling_people_vaccinated/population)*100
from percent_population_vaccinated;

--create view to store data for visualisation
create view percent_of_people_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

SELECT * FROM percent_of_people_vaccinated
LIMIT 100;