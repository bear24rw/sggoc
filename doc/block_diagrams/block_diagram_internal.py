from pydot import *

graph = graph_from_dot_file("block_diagram_internal.dot")

sggoc = graph.get_subgraph('clusterSGGoC')[0]

MIN = 1.7
SEP = 0.2

graph.get_node('monitor')[0].set_width(str(MIN))
sggoc.get_node('vga_ctl')[0].set_width(str(MIN))
sggoc.get_node('v_ram')[0].set_width(str(MIN))
sggoc.get_node('vdp')[0].set_width(str(MIN*2+SEP))

graph.get_node('speakers')[0].set_width(str(MIN))
sggoc.get_node('audio')[0].set_width(str(MIN))
sggoc.get_node('psg')[0].set_width(str(MIN))

graph.get_node('controller')[0].set_width(str(MIN))
sggoc.get_node('joystick')[0].set_width(str(MIN))

sggoc.get_node('io_ctl')[0].set_width(str(MIN*4+SEP*3))

sggoc.get_node('sys_ram')[0].set_width(str(MIN))
sggoc.get_node('flash')[0].set_width(str(MIN))
sggoc.get_node('mapper')[0].set_width(str(MIN))
sggoc.get_node('mmu')[0].set_width(str(MIN*2+SEP))


sggoc.get_node('z80')[0].set_width(str(MIN*2+SEP+MIN*4+SEP*3+SEP))


graph.write_png('block_diagram_internal.png')
graph.write_pdf('block_diagram_internal.pdf')
