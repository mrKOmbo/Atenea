# GTFS export

This folder contains a small script, `export.py`, that reads GTFS text files and emits a simplified transit graph CSV (`transit_graph.csv`).

## What `export.py` does (high-level)

- Reads GTFS plain text files (CSV) from the working directory: `agency.txt`, `routes.txt`, `trips.txt`, `stops.txt`, and `stop_times.txt`.
- Joins `routes` with `agency` and `trips` to enrich trip records with agency/route metadata.
- Joins `stop_times` with `stops` to include stop names and coordinates.
- For each trip, pairs each stop with the next stop in the sequence and computes the travel time between the departure of the origin stop and the arrival at the next stop.
- Produces `transit_graph.csv` with columns:
  - `agency_name`
  - `route_long_name`
  - `route_short_name`
  - `origin_stop`, `origin_lat`, `origin_lon`
  - `destiny_stop`, `destiny_lat`, `destiny_lon`
  - `time_of_journey` (HH:MM:SS)

## Inputs

The script expects these files available in the current working directory (no path prefix):

- `agency.txt`
- `routes.txt`
- `trips.txt`
- `stops.txt`
- `stop_times.txt`

Files are read using `pandas.read_csv` with default options. If your GTFS files are in a different directory, either `cd` to this folder before running, or use the `run_export.py` runner provided here which will change the working directory for you.

## Output

- `transit_graph.csv` in the working directory.
