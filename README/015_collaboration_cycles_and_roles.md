# Collaboration Cycles and Roles

## Purpose

This document explains the relationship between the two recurring movements of software collaboration and the responsibilities of the Architect and Engineer.

## Cycle terminology

- **Translational Cycle** — the formal collaboration term for the Data Interchange Cycle (DIC). It moves repository state and work between the Architect's persistent environment and the Engineer's workbench. Its Earth analogy is revolution: Earth travels around the Sun.
- **Rotational Cycle** — the formal collaboration term for the Iterative Development Cycle (IDC). It accomplishes assigned tasks and advances the software through repeated development, execution, testing, evaluation, and refinement. Its Earth analogy is rotation: Earth spins around its own axis.

DIC and IDC remain valid technical abbreviations. Translational Cycle and Rotational Cycle are the preferred terms in ordinary collaboration because they make the two movements easier to distinguish and remember.

## The Earth analogy

Earth simultaneously rotates on its axis and revolves around the Sun. Rotation produces the familiar daily cycle of day and night; revolution marks the larger yearly journey. People can experience and understand rotation without being aware of Earth's revolution. In the same way, the Engineer can carry out many Rotational Cycles—accomplishing tasks and improving the software—without needing to think about the Translational Cycle. Translation is the larger movement that transfers work between environments and accommodates the results of development when an exchange is needed. The two cycles are distinct, coordinated loops, not competing processes.

## Architect and Engineer responsibilities

The Architect is primarily associated with the Translational Cycle: defining direction and priorities, owning the persistent repository, authorizing work and exchanges, and reviewing what moves between environments.

The Engineer is primarily associated with the Rotational Cycle: investigating assigned objectives, implementing changes, executing and validating them, evaluating evidence, and reporting results.

These are primary responsibilities, not exclusive ownership. The Architect participates in development decisions during rotations, and the Engineer participates in preparing, validating, and coordinating translations. Both collaborate in both cycles.

## Relationship and coupling

The Rotational Cycle can operate independently and does not need to depend on or explain the Translational Cycle. The Translational Cycle must accommodate rotational work when developed changes are prepared for exchange, so it may refer to the Rotational Cycle where necessary.

Keep that relationship loosely coupled. A translational procedure should state only what it needs to know about development readiness and should not reproduce rotational procedures. Detailed development steps belong with the Rotational Cycle. The Rotational Cycle should not acquire a reciprocal dependency merely to explain how its results may later be transferred.
