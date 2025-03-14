// app/javascript/controllers/map_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "selectedList", "storesList"]
  
  connect() {
    console.log("Map controller connected")
    this.selectedNeighborhoods = new Set()
    this.neighborhoodLayers = {}
    this.initializeMap()
  }
  
  initializeMap() {
    // Initialize map
    this.map = L.map(this.mapTarget).setView([40.7128, -74.0060], 12)
    
    // Define styles
    this.defaultStyle = {
      fillColor: '#3388ff',
      weight: 2,
      opacity: 1,
      color: '#3388ff',
      fillOpacity: 0.2
    }
    
    this.selectedStyle = {
      fillColor: '#ff4500',
      weight: 3,
      opacity: 1,
      color: '#ff4500',
      fillOpacity: 0.4
    }
    
    // Add tile layer (OpenStreetMap)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)
    
    this.loadNeighborhoods()
  }
  
  loadNeighborhoods() {
    fetch('/neighborhoods.json')
      .then(response => response.json())
      .then(data => {
        // Add neighborhood polygons to the map
        const geoJsonLayer = L.geoJSON(data, {
          style: () => this.defaultStyle,
          onEachFeature: (feature, layer) => this.onEachFeature(feature, layer)
        }).addTo(this.map)
        
        // Fit the map to the neighborhood boundaries
        if (data.features.length > 0) {
          this.map.fitBounds(geoJsonLayer.getBounds())
        }
      })
      .catch(error => {
        console.error('Error fetching neighborhood data:', error)
      })
  }
  
  onEachFeature(feature, layer) {
    // Store reference to this layer
    const neighborhoodId = feature.properties.id
    this.neighborhoodLayers[neighborhoodId] = layer
    
    // Add a popup with the neighborhood name
    if (feature.properties && feature.properties.name) {
      layer.bindPopup(feature.properties.name)
    }
    
    // Add click handler to select/deselect neighborhood
    layer.on('click', (e) => {
      // Stop the click from propagating to the map
      L.DomEvent.stopPropagation(e)
      
      // Toggle selection
      if (this.selectedNeighborhoods.has(neighborhoodId)) {
        // Deselect
        this.selectedNeighborhoods.delete(neighborhoodId)
        layer.setStyle(this.defaultStyle)
      } else {
        // Select
        this.selectedNeighborhoods.add(neighborhoodId)
        layer.setStyle(this.selectedStyle)
      }
      
      // Update the UI
      this.updateSelectedNeighborhoodsUI()
      this.loadGroceryStoresForSelectedNeighborhoods()
    })
  }

  updateSelectedNeighborhoodsUI() {
    if (!this.hasSelectedListTarget) return

    this.selectedListTarget.innerHTML = ''

    if (this.selectedNeighborhoods.size == 0) {
        this.selectedListTarget.innerHTML = '<p>No neighborhoods selected</p>'
        return
    }

    // Create list of selected neighborhoods
    const ul = document.createElement('ul')
    ul.className = 'list-group'

    this.selectedNeighborhoods.forEach(id => {
        const layer = this.neighborhoodLayers[id]
        if (!layer) return

        // Get neighborhood name from layer
        const name = layer.feature.properties.name

        const li = document.createElement('li')
        li.className = 'list-group-item d-flex justify-content-between align-items-center'
        li.textContent = name

        // Add a remove button
        const removeBtn = document.createElement('button')
        removeBtn.className = 'btn btn-sm btn-outline-danger'
        removeBtn.textContent = 'x'
        removeBtn.dataset.action = "click->map#removeNeighborhood"
        removeBtn.dataset.mapNeighborhoodIdParam = id

        li.appendChild(removeBtn)
        ul.appendChild(li)
    })

    this.selectedListTarget.appendChild(ul)
  }

  removeNeighborhood(event) {
    const id = event.params.neighborhoodId
    const layer = this.neighborhoodLayers[id]

    if (layer) {
        this.selectedNeighborhoods.delete(id)
        layer.setStyle(this.defaultStyle)
        this.updateSelectedNeighborhoodsUI()
        this.loadGroceryStoresForSelectedNeighborhoods()
    }
  }

  loadGroceryStoresForSelectedNeighborhoods() {
    if (!this.hasStoresListTarget) return

    if (this.selectedNeighborhoods.size == 0) {
        this.storesListTarget.innerHTML = '<p>Select a neighborhood to see grocery stores</p>'
        return
    }

    // Convert set to array for API call
    const neighborhoodIds = Array.from(this.selectedNeighborhoods).join(',')

    fetch(`/neighborhoods/stores?ids=${neighborhoodIds}`)
    .then(response => response.json())
    .then(data => {
        this.storesListTarget.innerHTML = ''

        if (data.stores.length == 0) {
            this.storesListTarget.innerHTML = '<p>No grocery stores found in selected neighborhoods</p>'
            return
        }

        const storesHeader = document.createElement('h4')
        storesHeader.textContent = 'Grocery Stores'
        this.storesListTarget.appendChild(storesHeader)

        const ul = document.createElement('ul')
        ul.className = 'list-group'

        data.stores.forEach(store => {
            const li = document.createElement('li')
            li.className = 'list-group-item'
            li.innerHTML = `
                <strong>${store.name}</strong><br>
                ${store.address}<br>
                <small class="text-muted">Neighborhood: ${store.neighborhood_name}</small>
              `
              ul.appendChild(li)
        })

        this.storesListTarget.appendChild(ul)
    })
    .catch(error => {
      console.error('Error fetching grocery stores:', error);
      this.storesListTarget.innerHTML = '<p class="text-danger"> Error loading grocery stores.</p>';
    })
  }
}