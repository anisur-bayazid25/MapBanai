# Boundaries, survey layers and recurring measurements

This workflow applies to any project or study location. Boundary names,
facility types, questionnaires, measurement units and round dates are chosen
by the project team.

## 1. Create the project and forms

Create/select a project in Home → Project settings. In Survey, build or import
separate questionnaires for boundaries, facilities and measurements as needed.
Include a location (geopoint) question in surveys that will become point layers.
Use stable station names/IDs and consistent measurement names and units.

Survey now exposes the same project, study-layer and form selector used by GIS.
Choose Study layer → Add new Layer before collecting a separate dataset.
Saved responses retain that layer identity; drafts do not become mapped data.

## 2. Capture and save the boundary

For a walked boundary, select a named boundary study layer in GIS, choose Draw
Polygon, position the start marker, press Start, walk the perimeter, then Finish
and save. The selected questionnaire opens for attributes, if configured.

For a hand-drawn boundary, press the hand-drawing button beside the GPS indicator
in GIS. It is off when GIS opens. Choose Point, Line or Polygon from the toolbar,
then tap the map to place vertices. Undo removes the last vertex; Finish opens
the attribute form. Save draft and History resume preserve manual drawings.
Finish or cancel a feature before switching back to walking capture. For polygons,
use at least three distinct vertices enclosing an area. No GPS fix is needed to
draw by hand, so inaccessible edges can be mapped from the basemap.

Use GIS → Layer options → Save as project layer, or Project settings → Project
layers → Create layer from responses. Enter a boundary name, select its
source study layer and questionnaire (or All questionnaires for GIS records
without a form), enable Boundary / reference layer, preview and Create.
Only polygons are accepted for boundary layers. In Project settings → project
vector layers, manage its visibility, colour and opacity. Reference boundaries
remain visible behind another selected layer in Study Area.
The workflow chips assign each saved layer to Field Verification, Recurring
Collection, Study Area Visits or any combination, like an imported shapefile.
The original GIS records and their existing exports remain available.

## 3. Map facilities or other features

Create/select a separate study layer and facility questionnaire in Survey.
Run one response per feature, recording its name, type, location and other
attributes. GIS is another entry route for point, line or polygon geometry
followed by the questionnaire.

Choose Survey → Create layer from responses, name the output, select the
facility source layer and questionnaire, leave Boundary / reference layer off,
preview and Create. The resulting project layer can be selected in Study Area
for verification or visits and appears in the project atlas.

The same builder is available from Project settings → Project layers. Select
a questionnaire, then optionally a Filter question. Select one or more answer
values: a response is included if it matches any selected value. Multi-select
answers match individual choice codes rather than partial words. Declared choices
and observed saved values are available; drafts and deleted records are excluded.
Select one or more GPS questions to map exactly those answers. Each selected GPS
answer produces a separate point with its source response ID and question name;
missing/invalid points are skipped. Without a GPS selection, the saved geometry
is used. Preview the matching count before creating the layer, then assign its
workflow, type, colour, visibility and opacity in the layer settings.

Features inside and outside the boundary can be collected. The boundary is a
visual reference; collection does not automatically clip or block outside sites.

## 4. Establish measurement sites

Collect a baseline questionnaire with a GPS point and numeric measurements.
For example, the measurement may be salinity, water level or temperature.
Choose Survey → Create layer from responses to create a site layer from all
mapped responses in the chosen dataset.

For only responses containing one particular numeric measurement, use
Study Area → Recurring Collection → Create layer from responses. Choose the
questionnaire and measurement, name the layer, preview and Create recurring
layer. This existing route accepts valid point measurements and keeps one
site per source site identity.

These operations create a snapshot. Later survey responses do not automatically
change it. Creating another snapshot makes a separate layer. Original responses
remain saved. Avoid making a fresh site layer for every recurring visit.

## 5. Collect named rounds without overwriting measurements

Open Study Area → Recurring Collection. Select the project, site layer and
measurement questionnaire. Choose New collection round, give it a name, optional
season/period and date, then open the map. Visit each site, fill the form and
save the observation. Each round has its own completion state.

At the next visit, select the **same site layer**, create a new round and collect
again. Earlier observations remain separate records linked to the same site.
Use the site's timeline to compare recurring observations and export its history.
Editing a site's attributes instead changes its current state; use the collection
form for a new measurement.

An initial ordinary Survey response used to create a site layer is retained as
a baseline source response. Creating the layer does **not** retroactively turn
that response into a named round or link it to the new site's timeline. To have
Round 1 in the recurring timeline from the start, establish the site locations
first, then record the first measurements through Recurring Collection.

## 6. Review and share

GIS opens with a full map, a compact project/layer selector and a toolbar. Tap
the selector to change project/layer/form without leaving the map. The tune
button opens point/line/polygon filters and an opacity slider. Reference boundary
layers remain visible when filtering the active geometry type. Panels scroll on
small screens; the map continues behind the toolbar. The GPS indicator opens
coordinate/accuracy details on demand.

Use Study Area to see the boundary behind the selected site layer. WebMap
combines project data and offers layer filters and exports. Review Field quality,
export the project with responses/photos for backup or sharing, and use the
project's configured sync connection when available.

Before fieldwork, verify polygon capture, location permissions, round creation,
and exports on the target phone. Native GPS/camera behaviour and offline map
availability depend on the device and prepared basemap packages.
