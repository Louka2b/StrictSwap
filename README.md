# StrictSwap - The Ultimate Push_swap Tester
[![ldeplace's 42 stats](https://42cv.dev/api/badge/cmmm23yq10000dgywpv8dqd2n/stats?cursusId=21&coalitionId=48)](https://42cv.dev/ldeplace)


StrictSwap is a robust testing script designed to stress-test the push_swap project. It goes beyond simple sorting checks by verifying memory, norm compliance, and repository integrity.

## Main Features

    Sorting Validation: Automatic check using the official checker_linux.

    Performance Grading: Real-time scoring out of 5 for 100 and 500 element lists.

    Memory Security: Deep Valgrind integration to catch leaks during errors or successful runs.

    Subtle Edge Cases: Tests duplicates (0/-0), forbidden signs (+42), empty arguments, and INT limits.

    Zero-Waste: Operates entirely in RAM. No temporary files are created on your machine.

    Bilingual Interface: Full support for English (default) and French (-fr).

    Optional Security: Advanced crash detection with Funcheck (--funcheck).

## Installation

    Place tester.sh in the root of your push_swap directory.

    Give it execution rights: chmod +x tester.sh

## Usage

Simple run (English): ```./tester.sh```

French version: ```./tester.sh -fr```

## Evaluation Criteria

The tester follows the 42 school requirements:

    3 numbers: Under 3 moves.

    5 numbers: Under 12 moves.

    100 numbers: 5 pts (< 700) to 1 pt (< 1500).

    500 numbers: 5 pts (< 5500) to 1 pt (< 11500).

## Error Reporting

If a test fails, StrictSwap will prompt you to display the Trace Details. It provides the exact command line to reproduce the bug, allowing for instant debugging.

_Happy Coding by louka2b!_
