from pydot import *

graph = graph_from_dot_file("block_diagram_internal.dot")

sggoc = graph.get_subgraph('clusterSGGoC')[0]

WIDTH = 1.7
SEP = 0.2

def span(x):
    return str(WIDTH*x+SEP*(x-1))

graph.get_node('monitor')[0].set_width(span(1))
sggoc.get_node('vga_ctl')[0].set_width(span(1))
sggoc.get_node('v_ram')[0].set_width(span(1))
sggoc.get_node('vdp')[0].set_width(span(2))

graph.get_node('speakers')[0].set_width(span(1))
sggoc.get_node('audio')[0].set_width(span(1))
sggoc.get_node('psg')[0].set_width(span(1))

graph.get_node('controller')[0].set_width(span(1))
sggoc.get_node('joystick')[0].set_width(span(1))

sggoc.get_node('io_ctl')[0].set_width(span(4))

sggoc.get_node('sys_ram')[0].set_width(span(1))
sggoc.get_node('flash')[0].set_width(span(1))
sggoc.get_node('mapper')[0].set_width(span(1))

sggoc.get_node('mmu')[0].set_width(span(6))
sggoc.get_node('z80')[0].set_width(span(6))

graph.write_png('block_diagram_internal.png')
graph.write_pdf('block_diagram_internal.pdf')

def decolor():
    for n in graph.get_nodes():
        n.set_style('""')
    for n in sggoc.get_nodes():
        n.set_style('""')

def color():
    graph.get_node('monitor')[0].set_style('filled')
    graph.get_node('speakers')[0].set_style('filled')
    graph.get_node('controller')[0].set_style('filled')
    for n in sggoc.get_nodes():
        n.set_style('"filled"')

decolor()
sggoc.get_node('z80')[0].set_style('filled')
graph.write_png('block_diagram_internal_tv80.png')

decolor()
sggoc.get_node('mmu')[0].set_style('filled')
graph.write_png('block_diagram_internal_mmu.png')

decolor()
sggoc.get_node('vdp')[0].set_style('filled')
graph.write_png('block_diagram_internal_vdp.png')

decolor()
sggoc.get_node('io_ctl')[0].set_style('filled')
graph.write_png('block_diagram_internal_io_ctl.png')

decolor()
sggoc.get_node('mapper')[0].set_style('filled')
sggoc.get_node('flash')[0].set_style('filled')
graph.write_png('block_diagram_internal_cart.png')

decolor()
sggoc.get_node('sys_ram')[0].set_style('filled')
sggoc.get_node('v_ram')[0].set_style('filled')
graph.write_png('block_diagram_internal_ram.png')

color()
sggoc.get_node('psg')[0].set_style('""')
sggoc.get_node('audio')[0].set_style('""')
sggoc.get_node('joystick')[0].set_style('""')
graph.get_node('controller')[0].set_style('""')
graph.get_node('speakers')[0].set_style('""')
graph.write_png('block_diagram_internal_implemented.png')
