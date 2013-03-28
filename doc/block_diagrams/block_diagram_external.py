from pydot import *

graph = graph_from_dot_file("block_diagram_external.dot")

WIDTH = 1.7
SEP = 0.2

def span(x):
    return str(WIDTH*x+SEP*(x-1))

graph.get_node('sggoc')[0].set_width(span(3))
graph.get_node('sggoc')[0].set_height(span(1))


graph.get_node('monitor')[0].set_width(span(1))
graph.get_node('speakers')[0].set_width(span(1))
graph.get_node('controller')[0].set_width(span(1))

graph.write_png('block_diagram_external.png')
graph.write_pdf('block_diagram_external.pdf')
