# Haul

A packing and travel organiser — build a bag, check it off, track the trip.

## What it does

- Bag management
- camera capture
- checklists
- weather
- print

## Targets

- iOS with widgets

## Structure

Key types:

- ``TripStore``
- ``CameraService``
- ``WeatherService``
- ``InsightsService``
- ``BagsListView``
- ``SuitcasePhotoView``
- ``PrintChecklistView``
- ``Backup`/`Blob``

Largest app in the batch by file count — 261 Swift files, including `AggregateFunctions` and a `Blob` store.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
