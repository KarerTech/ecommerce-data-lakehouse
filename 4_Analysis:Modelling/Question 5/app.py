import streamlit as st
import pandas as pd
import folium
from streamlit_folium import st_folium


st.set_page_config(
    page_title="Logistics Dashboard",
    page_icon="🚚",
    layout="wide"
)

st.title("🚚 Logistics & Route Analysis")
st.markdown(
    "Analyze transport routes, cargo volumes, and simulated truck fuel costs across multiple distribution centers.")


# Data Load with caching for better performance
@st.cache_data
def load_data():
    # Loads the optimized parquet files from your directory
    df_log = pd.read_parquet('Datamart_Tables/Parquet/dashboard_logistics.parquet')
    df_dc = pd.read_parquet('Datamart_Tables/Parquet/dashboard_distribution_centers.parquet')
    df_log['order_date'] = pd.to_datetime(df_log['order_date'])
    return df_log, df_dc


try:
    df_logistics, dist_centers = load_data()
except FileNotFoundError:
    st.error("❌ The Parquet files were not found. Please verify the path 'Datamart_Tables/Parquet/'.")
    st.stop()


st.sidebar.header("Options")
show_routes = st.sidebar.checkbox("Show Route Connections", value=False)

# Calendar Year (Multiselect)
available_years = sorted(df_logistics['year'].unique())
selected_years = st.sidebar.multiselect(
    "Select Calendar Years:",
    options=available_years,
    default=[available_years[-1]]  # Pre-selects the latest year by default
)

# Distribution Center (Multiselect)
dc_options = sorted(dist_centers['city'].unique())
selected_dc_cities = st.sidebar.multiselect(
    "Select Distribution Centers:",
    options=dc_options,
    default=dc_options  # All DCs are pre-selected by default
)

# Guard Rails: Check if selections are empty
if not selected_years:
    st.warning("⚠️ Please select a Year.")
    st.stop()

if not selected_dc_cities:
    st.warning("⚠️ Please select a Distribution Center.")
    st.stop()

# Restrict data based on selected YEARS and selected DCs
filtered_dcs = dist_centers[dist_centers['city'].isin(selected_dc_cities)]
df_filtered = df_logistics[
    (df_logistics['year'].isin(selected_years)) &
    (df_logistics['dc_city'].isin(selected_dc_cities))
]


# subheader for multiple years
years_display = ", ".join(map(str, sorted(selected_years)))
st.subheader(f"Selected Years: {years_display}")

# KPI cards
total_items_shipped = df_filtered['total_items'].sum()
total_costs = df_filtered['logistics_costs_total'].sum()
avg_distance = df_filtered['distance_miles'].mean()

col1, col2, col3 = st.columns(3)
with col1:
    st.metric(label="Total Items Shipped", value=f"{int(total_items_shipped):,} pcs.")
with col2:
    st.metric(label="Simulated Truck Fuel Costs", value=f"$ {total_costs:,.2f}")
with col3:
    st.metric(label="Ø Transport Distance",
              value=f"{avg_distance:,.1f} miles" if not pd.isna(avg_distance) else "0 miles")

st.markdown("---")

# Folium map


if not df_filtered.empty:
    # Dynamic map center
    if len(selected_dc_cities) == 1:
        dc_coords = filtered_dcs.iloc[0]
        map_center = [dc_coords['latitude'], dc_coords['longitude']]
        zoom_start = 5
    else:
        map_center = [39.5, -98.35]  # US Geographical center
        zoom_start = 4

    m = folium.Map(location=map_center, zoom_start=zoom_start, tiles="cartodbpositron")

    # Unique color palette for lines from different DCs
    colors = ['#1a6faf', '#e31a1c', '#33a02c', '#ff7f00', '#6a3d9a', '#b15928', '#a6cee3', '#b2df8a', '#fdbf6f',
              '#cab2d6']

    # Calculate state centroids for destination circle markers
    state_agg = df_filtered.groupby('customer_state').agg(
        state_lat=('state_lat', 'mean'),
        state_lon=('state_lon', 'mean'),
        total_items=('total_items', 'sum')
    ).reset_index()

    max_orders_state = state_agg['total_items'].max() if not state_agg.empty else 1

    # Draw routes and markers specific to each selected DC
    for idx, (_, dc) in enumerate(filtered_dcs.iterrows()):
        dc_color = colors[idx % len(colors)]

        # Set marker for the distribution center
        folium.Marker(
            location=[dc['latitude'], dc['longitude']],
            popup=folium.Popup(f"<b>CENTER: {dc['city']} ({dc['state']})</b>", max_width=200),
            tooltip=f"DC: {dc['city']}",
            icon=folium.Icon(color='blue', icon='warehouse', prefix='fa')
        ).add_to(m)

        # Filter route data for specific DC
        dc_specific_df = df_filtered[df_filtered['distribution_center_id'] == dc['id']]

        # Aggregate by state for specific DC
        dc_route_agg = dc_specific_df.groupby('customer_state').agg(
            items_route=('total_items', 'sum'),
            costs_route=('logistics_costs_total', 'sum'),
            dest_lat=('state_lat', 'mean'),
            dest_lon=('state_lon', 'mean')
        ).reset_index()

        # Draw connection lines for DC
        for _, route in dc_route_agg.iterrows():
            if route['items_route'] == 0:
                continue

            start_coords = [dc['latitude'], dc['longitude']]
            end_coords = [route['dest_lat'], route['dest_lon']]

            # Dynamic line weight based on item volume
            weight_calc = max(1.0, min(route['items_route'] / 20, 12.0))

            info_text = (
                f"<b>Route:</b> {dc['city']} ➔ {route['customer_state']}<br>"
                f"<b>Volume for Selection:</b> {int(route['items_route'])} pcs.<br>"
                f"<b>Simulated Fuel Costs:</b> $ {route['costs_route']:,.2f}"
            )
            if show_routes:
                folium.PolyLine(
                    locations=[start_coords, end_coords],
                    color=dc_color,
                    weight=weight_calc,
                    opacity=0.4,
                    tooltip=f"{dc['city']} to {route['customer_state']} ({int(route['items_route'])} Items)",
                    popup=folium.Popup(info_text, max_width=300)
                ).add_to(m)


    # Overlay destination centers as green circles
    for _, row in state_agg.iterrows():
        if row['total_items'] == 0:
            continue

        # Radius scales dynamically based on total volume of the destination state
        radius_calc = 5 + (row['total_items'] / max_orders_state) * 15

        folium.CircleMarker(
            location=[row['state_lat'], row['state_lon']],
            radius=radius_calc,
            color='#2ca02c',
            fill=True,
            fill_color='#2ca02c',
            fill_opacity=0.6,
            tooltip=f"Destination State: {row['customer_state']}",
            popup=f"<b>State: {row['customer_state']}</b><br>Total Volume: {int(row['total_items'])} pcs."
        ).add_to(m)

    # Render map
    st_folium(m, use_container_width=True, height=800, returned_objects=[])

else:
    st.info("ℹ️ No data available.")