import numpy as np
import netCDF4 as nc
import subprocess
import time


def execute_shell_command(command):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        print("Command executed successfully:")
        print(f'{command}')
        print(result.stdout)
    else:
        print("Error executing command:")
        print(f'{command}')
        print(result.stderr)


def change_time_var_dim(filename, new_filename):
    cmd = ["ncrename", "-v", "valid_time,time", f'{filename}', f'temp.nc']
    execute_shell_command(cmd)
    cmd = ["ncrename", "-d", "valid_time,time", f'temp.nc', f'{new_filename}']
    execute_shell_command(cmd)

    with nc.Dataset(filename, 'r') as ncfile:
        with nc.Dataset(new_filename, 'r+') as new_ncfile:
            new_ncfile.variables['time'][:] = ncfile.variables['valid_time'][:]

    cmd = ["rm", "-rf", f'temp.nc']
    execute_shell_command(cmd)


def replace_file(filename, new_filename):
    cmd = ["mv", f'{new_filename}',f'{filename}']
    execute_shell_command(cmd)
    cmd = ["rm", "-rf", f'{new_filename}']
    execute_shell_command(cmd)


def reverse(filename, variable='latitude'):

    with nc.Dataset(filename, 'r+') as ncfile:

        batch_size = 500

        len_lat = len(ncfile.variables[variable])

        residual = len_lat % batch_size

        corresponding_batches = int(len_lat / batch_size)

        # if corresponding_batches is not pair add a batch to the residual making max residual (batch_size*2 - 1)
        if (corresponding_batches % 2):
            corresponding_batches -= 1
            residual += batch_size

        cb = int(corresponding_batches/2)
        bs = batch_size

        for var_name in ncfile.variables:
            if var_name == variable:
                for i in range(cb):
                    temp_start = ncfile.variables[variable][(i*bs):(i*bs + bs)].copy()
                    temp_start = temp_start[::-1]

                    temp_end = ncfile.variables[variable][((len_lat) - (i*bs + bs)):((len_lat) - (i*bs))].copy()
                    temp_end = temp_end[::-1]

                    ncfile.variables[variable][(i*bs):(i*bs + bs)] = temp_end
                    ncfile.variables[variable][((len_lat) - (i*bs + bs)):((len_lat) - (i*bs))] = temp_start

                ncfile.variables[variable][((cb)*bs):((cb)*bs + residual)] = ncfile.variables[variable][((cb)*bs):((cb)*bs + residual)][::-1]

                if (ncfile.variables[variable][0] - ncfile.variables[variable][1]) < 0 :
                    ncfile.variables[variable].setncattr('stored_direction', 'increasing')
                else:
                    ncfile.variables[variable].setncattr('stored_direction', 'decreasing')

            else:
                var = ncfile.variables[var_name]
                if variable in var.dimensions:
                    # assume latitude is placed as (time, latitude, longitude)

                    # the problem seems to be for large time
                    time_len = ncfile.variables[var_name].shape[0]
                    nb = int(time_len / batch_size)

                    for ii in range(nb):
                        for i in range(cb):
                            temp_start = ncfile.variables[var_name][(ii*bs):((ii+1)*bs), (i*bs):(i*bs + bs), :].copy()
                            temp_start = temp_start[:, ::-1, :]

                            temp_end = ncfile.variables[var_name][(ii*bs):((ii+1)*bs), ((len_lat) - (i*bs + bs)):((len_lat) - (i*bs)), :].copy()
                            temp_end = temp_end[:, ::-1, :]

                            ncfile.variables[var_name][(ii*bs):((ii+1)*bs), (i*bs):(i*bs + bs), :] = temp_end
                            ncfile.variables[var_name][(ii*bs):((ii+1)*bs), ((len_lat) - (i*bs + bs)):((len_lat) - (i*bs)), :] = temp_start

                        ncfile.variables[var_name][(ii*bs):((ii+1)*bs), ((cb)*bs):((cb)*bs + residual), :] = ncfile.variables[var_name][(ii*bs):((ii+1)*bs), ((cb)*bs):((cb)*bs + residual), :][:, ::-1, :]

                    if time_len % batch_size > 0:
                        for i in range(cb):
                            temp_start = ncfile.variables[var_name][(bs*nb):, (i*bs):(i*bs + bs), :].copy()
                            temp_start = temp_start[:, ::-1, :]

                            temp_end = ncfile.variables[var_name][(bs*nb):, ((len_lat) - (i*bs + bs)):((len_lat) - (i*bs)), :].copy()
                            temp_end = temp_end[:, ::-1, :]

                            ncfile.variables[var_name][(bs*nb):, (i*bs):(i*bs + bs), :] = temp_end
                            ncfile.variables[var_name][(bs*nb):, ((len_lat) - (i*bs + bs)):((len_lat) - (i*bs)), :] = temp_start

                        ncfile.variables[var_name][(bs*nb):, ((cb)*bs):((cb)*bs + residual), :] = ncfile.variables[var_name][(bs*nb):, ((cb)*bs):((cb)*bs + residual), :][:, ::-1, :]


def set_time_units(filename):
    with nc.Dataset(filename, 'a') as dataset:

        if 'time' in dataset.variables:
            time_var = dataset.variables['time']

            # Modify the 'units' attribute
            time_var.units = 'seconds since 1970-01-01 00:00:00.0 0:00'


def print_info(filename):
    with nc.Dataset(filename, 'r') as dataset:

        # Print global attributes
        print("\nGlobal attributes:")
        for attr_name in dataset.ncattrs():
            print(f" - {attr_name}: {getattr(dataset, attr_name)}")

        # Print the dimensions present in the file
        print("\nDimensions:")
        for dim_name, dimension in dataset.dimensions.items():
            print(f" - {dim_name} (size: {len(dimension)})")

        # Print the variables present in the file
        print("\nVariables:")
        for var_name, variable in dataset.variables.items():
            # Get variable attributes as a dictionary
            var_attrs = {attr_name: getattr(variable, attr_name) for attr_name in variable.ncattrs()}
            print(f" - {var_name}:")
            print(f"   Dtype: {variable.dtype}")
            print(f"   Dimensions: {variable.dimensions}")
            print(f"   Shape: {variable.shape}")
            print(f"   Attributes: {var_attrs}")

            print(f"   Values: {variable[:10]}")


def add_actual_range(filename):

    batch = 500
    with nc.Dataset(filename, 'r+') as ncfile:

        # Loop through each variable in the file
        for var_name in ncfile.variables:
            var_len = ncfile.variables[var_name].shape

            # Check if the variable has any data (to avoid issues with empty variables)
            if len(var_len) > 0:
                var_len = var_len[0]

                if type(ncfile.variables[var_name][0]) == str:
                    continue

                max_val = np.max(ncfile.variables[var_name][0])
                min_val = np.min(ncfile.variables[var_name][0])

                nb = int(var_len / batch)
                for i in range(nb):

                    temp_max = np.max(ncfile.variables[var_name][i*batch:(i+1)*batch])
                    temp_min = np.min(ncfile.variables[var_name][i*batch:(i+1)*batch])

                    if temp_max > max_val:
                        max_val = temp_max
                    if temp_min < min_val:
                        min_val = temp_min

                # check the remainder
                if var_len % batch > 0:
                    temp_max = np.max(ncfile.variables[var_name][nb*batch:])
                    temp_min = np.min(ncfile.variables[var_name][nb*batch:])

                    if temp_max > max_val:
                        max_val = temp_max
                    if temp_min < min_val:
                        min_val = temp_min

                # Add the "actual_range" attribute to the variable
                ncfile.variables[var_name].setncattr('actual_range', [min_val, max_val])


filename = '/Users/nilsenriccanuttaugbol/WW3/python/data/era5_wind_wave_ice_2020/data_stream-oper.nc'

new_filename = '/Users/nilsenriccanuttaugbol/WW3/python/data/data_wind_ice.nc'

print_info(filename)

start_time = time.time()

change_time_var_dim(filename, new_filename)

print("starting to reverse")
reverse(new_filename)

print("setting time units")
set_time_units(new_filename)

print("setting actual range")
add_actual_range(new_filename)

end_time = time.time()

print_info(new_filename)

print(f'Process took {end_time - start_time} seconds')

