import xarray as xr
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.animation import FuncAnimation
import matplotlib.colors as mcolors
import matplotlib.animation as animation
import matplotlib as mpl
import sys
from matplotlib.tri import Triangulation

mpl.rcParams['animation.convert_path'] = '/opt/homebrew/bin/magick'

print('What is the relative path wrt. WW3 ?')
rel_path = input()
print(f'And what is the name of the file ? I need only the * part in *.nc')
date = input()
# Load the NetCDF data
ds = xr.open_dataset(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}{date}.nc')

# Extract the latitude and longitude coordinates
latitudes = ds['latitude'].values
longitudes = ds['longitude'].values

# axis limits ?
print(f'Do you want axis limits ? y/n')
axis_limits = input()
if axis_limits == 'y':
    print(f'What is the longitude range ? min, max')
    ran = input().split(', ')
    print(f'What is the latitude range ? min, max')
    run = input().split(', ')

    lon_min = ran[0] if float(ran[0]) > 0 else f'N{float(ran[0])*-1}'
    lon_max = ran[1] if float(ran[1]) > 0 else f'N{float(ran[1])*-1}'
    lat_min = run[0] if float(run[0]) > 0 else f'N{float(run[0])*-1}'
    lat_max = run[1] if float(run[1]) > 0 else f'N{float(run[1])*-1}'

print(f'flip y-axis ? y/n')
flip = input()

def mapsta():
    # Prepare figure and axis
    fig, ax = plt.subplots(figsize=(10, 6))

    print(f'Triangular polygon mesh ? y/n')
    tri_grid = input()
    if tri_grid == 'y':
        triangles = ds['tri'].values - 1
        # Create an initial plot to get to the tripcolor and the colorbar
        triang = Triangulation(longitudes, latitudes, triangles)
        data_var = ds['MAPSTA'].values
        heatmap = ax.tripcolor(triang, data_var, cmap=plt.get_cmap('tab10', 10), norm=mcolors.BoundaryNorm(clip=True, boundaries=np.linspace(-2.5, 7.5, 11), ncolors=plt.get_cmap('tab10', 10).N), shading='flat')
        cbar = fig.colorbar(heatmap, ax=ax, ticks=np.arange(-2, 8))

    else:
        df = pd.DataFrame(ds['MAPSTA'].values, index=latitudes, columns=longitudes)
        heatmap = sns.heatmap(df, cmap=plt.get_cmap('tab10', 10), norm=mcolors.BoundaryNorm(clip=True, boundaries=np.linspace(-2.5, 7.5, 11), ncolors=plt.get_cmap('tab10', 10).N), cbar=True, ax=ax, shading='flat', cbar_kws={'ticks': np.arange(-2, 8)})

    if axis_limits == 'y':
        ax.set_xlim(float(ran[0]), float(ran[1]))
        ax.set_ylim(float(run[0]), float(run[1]))

    ax.set_title(f'MAPSTA')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    if flip == 'y':
        ax.invert_yaxis()
    ax.set_aspect('equal')

    plt.tight_layout()
    if axis_limits == 'y':
        plt.savefig(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}MAPSTA_zoom_lon{lon_min}_{lon_max}__lat{lat_min}_{lat_max}.pdf')
    else:
        plt.savefig(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}MAPSTA.pdf')

    plt.close()


    print(f'Plot only the map status ? y/n')
    if input() == 'y':
        exit()

# mapsta()

print("\nVariable Details:")
for var_name, var_data in ds.data_vars.items():
    print(f"\nVariable: {var_name}")
    print(f"  Dimensions: {var_data.dims}")
    print(f"  Attributes: {var_data.attrs}")
    print(f"  Data Type: {var_data.dtype}")

print("Type in the variables type you want to plot separated by ', ' (comma and space):")
variable_names = input()

print('Will you want shading ? y/n')
if input() == 'y':
    shading = 'gouraud'
else:
    shading='flat'

print(f'There are {ds.sizes["time"]} timestamps is the nc file.')
print('What do you want the fps to be ?')
fps = input()

for variable_name in variable_names.split(', '):
    # Compute the global min and max values for the variable across all time steps
    vmin = ds[variable_name].min().item()
    vmax = ds[variable_name].max().item()

    fig, ax = plt.subplots(figsize=(10, 6))

    if tri_grid == 'y':
        # Create an initial plot to get to the tripcolor and the colorbar
        triang = Triangulation(longitudes, latitudes, triangles)
        data_var = ds[variable_name].isel(time=0).values
        heatmap = ax.tripcolor(triang, data_var, vmin=vmin, vmax=vmax, cmap='Spectral_r', shading=shading)
        cbar = fig.colorbar(heatmap, ax=ax)
    else:
        # Create an initial plot to get reference to the colormesh and the colorbar
        data_var = ds[variable_name].isel(time=0).values
        heatmap = ax.pcolormesh(longitudes, latitudes, data_var, vmin=vmin, vmax=vmax, cmap='Spectral_r', shading=shading)
        cbar = fig.colorbar(heatmap, ax=ax)

    # Set y-axis inversion and aspect ratio
    # if flip == 'y':
    #     ax.invert_yaxis()
    ax.set_aspect('equal')

    if axis_limits == 'y':
        ax.set_xlim(float(ran[0]), float(ran[1]))
        ax.set_ylim(float(run[0]), float(run[1]))

    # Set labels
    ax.set_title(f'{variable_name} at time step 0')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    def animate(t):
        # Update the data for the current time step
        data_var = ds[variable_name].isel(time=t)
        data_2d = data_var.values

        # Change data within the existing heatmap
        heatmap_data = ax.collections[0]
        if tri_grid == 'y':
            heatmap_data.set_array(data_2d.ravel())
        else:
            heatmap_data.set_array(data_2d)

        # Update the title for the current time step
        ax.set_title(f'{variable_name} at time step {t}')

        # Force a redraw of the figure
        fig.canvas.draw_idle()

    # Create animation
    ani = FuncAnimation(fig, animate, frames=ds.sizes['time'], interval=1)

    shading_txt = shading if shading is not None else 'no'

    # Save the animation as a GIF
    if axis_limits == 'y':
        ani.save(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}{date}_{variable_name}_{shading_txt}shading_zoom_lon{lon_min}_{lon_max}__lat{lat_min}_{lat_max}.gif', writer=animation.ImageMagickWriter(fps=int(fps)))
    else:
        ani.save(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}{date}_{variable_name}_{shading_txt}shading.gif', writer=animation.ImageMagickWriter(fps=int(fps)))

    plt.close()

    # one last pdf plot of the last frame

    fig, ax = plt.subplots(figsize=(10, 6))

    if tri_grid == 'y':
        # Create an initial plot to get to the tripcolor and the colorbar
        triang = Triangulation(longitudes, latitudes, triangles)
        data_var = ds[variable_name].isel(time=ds.sizes["time"]-1).values
        heatmap = ax.tripcolor(triang, data_var, vmin=vmin, vmax=vmax, cmap='Spectral_r', shading=shading)
        cbar = fig.colorbar(heatmap, ax=ax)
    else:
        # Create an initial plot to get reference to the colormesh and the colorbar
        data_var = ds[variable_name].isel(time=ds.sizes["time"]-1).values
        lon_mesh, lat_mesh = np.meshgrid(longitudes, latitudes)
        heatmap = ax.pcolormesh(lon_mesh, lat_mesh, data_var, vmin=vmin, vmax=vmax, cmap='Spectral_r', shading=shading)
        cbar = fig.colorbar(heatmap, ax=ax)

    ax.set_title(f'{variable_name} at the last time step')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    if axis_limits == 'y':
        ax.set_xlim(float(ran[0]), float(ran[1]))
        ax.set_ylim(float(run[0]), float(run[1]))

    # if flip == 'y':
    #     ax.invert_yaxis()
    ax.set_aspect('equal')

    if axis_limits == 'y':
        plt.savefig(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}{date}_{variable_name}_{shading_txt}shading_zoom_lon{lon_min}_{lon_max}__lat{lat_min}_{lat_max}.pdf')
    else:
        plt.savefig(f'/Users/nilsenriccanuttaugbol/WW3/{rel_path}{date}_{variable_name}_{shading_txt}shading.pdf')


# end of plotting loop
# EOF

