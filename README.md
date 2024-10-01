# hexagrid-relaxed
Godot (GDScript) port of Cedric Guillemet's C++ [HexagridRelaxing repository](https://github.com/CedricGuillemet/HexagridRelaxing)

Game developer [Oskar Stålberg](https://x.com/osksta?lang=en) invented a procedural mesh generation algorithm to generate organic-looking grids. In a [nutshell](https://kurzgesagt.org/), the
algorithm is:

1. Tesselation
1. Relaxation
1. Determine neighbors

# Tesselation

* Tesselate a hexagon into a mesh of equilateral triangles
* Randomly merge a percentage of the triangles with a neighboring triangle to replace 2 triangles with a diamond-shaped quadrilateral
* Subdivide the quadrilaterals and triangles into smaller quadrilateral cells. Each cell's 4 vertices are:
  * A vertex of the containing shape
  * The midpoints of the two edges touching that vertex
  * The center point of the shape

# Relaxation

For each point, iteratively update its position with the average position of all of its neighbors. A consequence of averaging positions is that all points will converge on being a uniform distance from
their neighbors. The relaxation pass currently runs every frame when turned on.

## Edge relaxation

An optional relaxation pass solely on the edge vertices. Takes every edge vertex and pushes it away or pulls it towards the center of the hexagon so that all edges are a uniform distance from the center, yielding
a circular mesh.

# Determine neighbors

This is my own addition, as I plan to use this for generating navigable meshes. The vertices know their neighbors, and one can brute-force generate a list of any cell's neighbors by looping through the list of
all cells and making a list of every cell that shares exactly two vertices. Since the vertices are stored as an array and all shapes only store indices in that array, this is fairly quick.

But each quad can have 2, 3, or 4 neighbors. Since the quads are not axis-aligned, any list of neighbors may be random. You can mitigate this by strictly adding neighbors to the list such that you first add a neighbor
that shares vertices "A and B", then "B and C", then "C and D", then "D and A". That guarantees you a list of neighbors that is either clockwise or counter-clockwise, depending upon whether the ordering of the vertices
A, B, C, and D were clockwise or counter-clockwise.

I devised a system of checking the quads' midpoints with their neighbors' midpoints then checking the cross products to see whether they're positive or negative. If the cross products are negative, reverse the
neighbors list. All cells now have clockwise lists of neighbors.

# Next steps

* Don't generate a list of neighbors and their midpoints before determining whether a quad has clockwise or counter-clockwise vertices. Determine clock-wise-ness by looking at the quad itself at the moment of
  generation. Only need to look at the cross product of the first two vertices and, if they're negative, reverse the order of the points. This moves the clock-wise-ness test from neighbor generation as well as the
  need to reverse the neighbor list because every quad will be guaranteed to have clockwise points.
* Use the grid to make mazes!
* Use the grid to implement a map exploration algorithm!

  ![Default](/images/screen1.png "Default grid")
  ![Relaxed Grid](/images/screen2.png "Relaxed grid")
  ![Relaxed Edges](/images/screen3.png "Grid with relaxed edges")
