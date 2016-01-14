import UIKit

class FilterListViewController: UITableViewController {

    var filterDisplayViewController: FilterDisplayViewController? = nil
    var objects = NSMutableArray()

    // #pragma mark - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let filterInList = filterOperations[indexPath.row]
                (segue.destinationViewController as! FilterDisplayViewController).filterOperation = filterInList
            }
        }
    }

    // #pragma mark - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterOperations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let filterInList:FilterOperationInterface = filterOperations[indexPath.row]
        cell.textLabel?.text = filterInList.listName
        return cell
    }
}

