from pydot import *

graph = graph_from_dot_file("block_diagram_external.dot")

MIN = 1.7
SEP = 0.2

graph.get_node('sggoc')[0].set_width(str(MIN*3+SEP*2))
graph.get_node('sggoc')[0].set_height(str(MIN*2))


graph.get_node('monitor')[0].set_width(str(MIN))
graph.get_node('speakers')[0].set_width(str(MIN))
graph.get_node('controller')[0].set_width(str(MIN))

graph.write_png('block_diagram_external.png')
